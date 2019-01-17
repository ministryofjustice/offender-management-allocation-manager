require 'faraday'

module Nomis
  module Custody
    class Client
      APIError = Class.new(StandardError)

      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
          faraday.request :retry, max: 3, interval: 0.05,
                                  interval_randomness: 0.5, backoff_factor: 2,
                                  exceptions: [Faraday::ClientError, 'Timeout::Error']

          faraday.use Faraday::Response::RaiseError
          faraday.adapter Faraday.default_adapter
        end
      end

      def get(route)
        data = request(:get, route)
        if block_given?
          yield data
        end

        data
      end

    private

      def request(method, route)
        response = @connection.send(method) { |req|
          req.url(@host + route)
          req.headers['Authorization'] = "Bearer #{token.access_token}"
        }

        JSON.parse(response.body)
      rescue Faraday::ResourceNotFound, Faraday::ClientError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        raise APIError, "Unexpected status #{e.response[:status]}"
      end

      def token
        Nomis::Oauth::TokenService.valid_token
      end
    end
  end
end
