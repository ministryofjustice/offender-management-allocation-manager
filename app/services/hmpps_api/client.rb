# frozen_string_literal: true

require 'faraday'
require 'typhoeus/adapters/faraday'

module HmppsApi
  class Client
    def initialize(root, extra_retry_methods: [], user_token: nil)
      @root = root
      @user_token = user_token
      @connection = Faraday.new do |faraday|
        faraday.request :retry, max: 3, interval: 0.05,
                                interval_randomness: 0.5, backoff_factor: 2,
                                # We appear to get occasional transient 5xx errors, so retry them
                                retry_statuses: [500, 502],
                                methods: Faraday::Request::Retry::IDEMPOTENT_METHODS + extra_retry_methods,
                                # we get Faraday::ConnectionFailed (error in HTTP2 Framing Layer) sometimes
                                exceptions: Faraday::Request::Retry::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]

        faraday.options.params_encoder = Faraday::FlatParamsEncoder
        faraday.request :instrumentation
        # Response middleware is supposed to be registered after request middleware
        faraday.response :raise_error
        faraday.adapter :typhoeus
      end
    end

    # Performs a basic GET request without processing the response. This is mostly
    # used for when we do not want a JSON response from an endpoint.
    def raw_get(route, queryparams: {}, extra_headers: {}, cache: false)
      response = request(
        :get, route, queryparams: queryparams, extra_headers: extra_headers, cache: cache
      )
      response.body
    end

    def get(route, queryparams: {}, extra_headers: {}, cache: true)
      response = request(
        :get, route, queryparams: queryparams, extra_headers: extra_headers, cache: cache
      )

      # Elite2 can return a 204 to mean empty results, and we don't know if
      # it is meant to be a {} or a []. For now, we are going to use nil and
      # let the caller handle it.
      data = if response.status == 204
               nil
             else
               JSON.parse(response.body)
             end

      if block_given?
        yield data, response
      end

      data
    end

    def post(route, body, queryparams: {}, extra_headers: {}, cache: false)
      response = request(
        :post, route, queryparams: queryparams, extra_headers: extra_headers, body: body, cache: cache
      )

      JSON.parse(response.body)
    end

    def put(route, body, queryparams: {}, extra_headers: {})
      response = request(
        :put, route, queryparams: queryparams, extra_headers: extra_headers, body: body
      )

      JSON.parse(response.body)
    end

    def delete(route, queryparams: {}, extra_headers: {})
      request(
        :delete, route, queryparams: queryparams, extra_headers: extra_headers
      )
    end

    def expire_cache_key(method, route, queryparams: {}, extra_headers: {}, body: nil)
      response_cache.expire(method:, route:, queryparams:, extra_headers:, body:)
    end

  private

    def request(method, route, queryparams: {}, extra_headers: {}, body: nil, cache: false)
      log_prefix = "[#{self.class}] [#{@root}] method=#{method.upcase},route=#{route}"

      unless cache
        Rails.logger.info("#{log_prefix},event=cache_disabled")
        return send_request(method, route, queryparams:, extra_headers:, body:)
      end

      cached_response = response_cache.read(method:, route:, queryparams:, extra_headers:, body:)

      if cached_response
        Rails.logger.info("#{log_prefix},event=cache_hit")
        return cached_response
      end

      Rails.logger.info("#{log_prefix},event=cache_miss")

      response = send_request(method, route, queryparams:, extra_headers:, body:)
      if cacheable_response?(response)
        response_cache.write(
          method:, route:, queryparams:, extra_headers:, body:, response:
        )
      end

      response
    end

    def send_request(method, route, queryparams:, extra_headers:, body:)
      url = @root + route
      bearer = @user_token || token.access_token

      @connection.send(method) do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.headers['Content-Type'] = 'application/json' unless body.nil?
        req.headers.merge!(extra_headers)
        req.params.update(queryparams)
        req.body = body.to_json unless body.nil?
      end
    rescue Faraday::UnauthorizedError => e
      Rails.logger.error("[#{self.class}] #{url} -- #{e.message}")

      # cast and re-raise as it is handled up the chain
      raise HmppsApi::Error::Unauthorized, e
    end

    def cacheable_response?(response)
      return false if response.status == 204
      return false if empty_response_body?(response)

      true
    end

    def empty_response_body?(response)
      body = response.body.to_s.strip
      return true if body.empty?

      parsed = JSON.parse(body)
      parsed.respond_to?(:empty?) && parsed.empty?
    rescue JSON::ParserError
      false
    end

    def token
      HmppsApi::Oauth::TokenService.valid_token
    end

    def response_cache
      @response_cache ||= HmppsApi::ResponseCache.new(@root)
    end
  end
end
