require 'faraday'
require 'typhoeus/adapters/faraday'

module Nomis
  class Client
    APIError = Class.new(StandardError)

    def initialize(host)
      @host = host
      @connection = Faraday.new do |faraday|
        faraday.request :retry, max: 3, interval: 0.05,
                                interval_randomness: 0.5, backoff_factor: 2,
                                exceptions: [Faraday::ClientError, 'Timeout::Error']

        faraday.options.params_encoder = Faraday::FlatParamsEncoder
        faraday.use Faraday::Response::RaiseError
        faraday.adapter :typhoeus
      end
    end

    def get(route, queryparams: {}, extra_headers: {})
      response = request(
        :get, route, queryparams: queryparams, extra_headers: extra_headers
      )
      data = JSON.parse(response.body)

      if block_given?
        yield data, response
      end

      data
    end

    def post(route, body)
      response = request(
        :post, route, body: body
      )
      JSON.parse(response.body)
    end

  private

    # rubocop:disable Metrics/MethodLength
    def request(method, route, queryparams: {}, extra_headers: {}, body: nil)
      @connection.send(method) do |req|
        req.url(@host + route)
        req.headers['Authorization'] = "Bearer #{token.access_token}"
        req.headers['Content-Type'] = 'application/json' if method == :post
        req.headers.merge!(extra_headers)
        req.params.update(queryparams)
        req.body = body.to_json if body.present? && method == :post
      end
    rescue Faraday::ResourceNotFound, Faraday::ClientError => e
      AllocationManager::ExceptionHandler.capture_exception(e)
      raise APIError, "Unexpected status #{e.response[:status]}"
    end
    # rubocop:enable Metrics/MethodLength

    def token
      Nomis::Oauth::TokenService.valid_token
    end
  end
end
