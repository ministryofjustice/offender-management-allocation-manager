require 'faraday'
require 'typhoeus/adapters/faraday'

module Allocation
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

    def get(route)
      request(:get, route)
    end

    def post(route, body)
      request(:post, route, body: body)
    end

  private

    def request(method, route, body: nil)
      response = @connection.send(method) { |req|
        req.url(@host + route)
        req.headers['Authorization'] = "Bearer #{token.access_token}"
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json if body.present? && method == :post
      }

      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      AllocationManager::ExceptionHandler.capture_exception(e)
      raise APIError, "Unexpected status #{e.response[:status]}"
    end

    def token
      Nomis::Oauth::TokenService.valid_token
    end
  end
end
