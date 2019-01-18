require 'faraday'

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
        faraday.adapter Faraday.default_adapter
      end
    end

    def get(route, queryparams: nil, extra_headers: nil)
      response = request(
        :get, route, queryparams: queryparams, extra_headers: extra_headers
      )
      data = JSON.parse(response.body)

      if block_given?
        yield data, response
      end

      data
    end

  private

    def request(method, route, queryparams: nil, extra_headers: nil)
      @connection.send(method) do |req|
        req.url(@host + route)
        req.headers['Authorization'] = "Bearer #{token.access_token}"
        req.headers.merge!(extra_headers || {})
        req.params.update(queryparams || {})
      end
    rescue Faraday::ResourceNotFound, Faraday::ClientError => e
      AllocationManager::ExceptionHandler.capture_exception(e)
      raise APIError, "Unexpected status #{e.response[:status]}"
    end

    def token
      Nomis::Oauth::TokenService.valid_token
    end
  end
end
