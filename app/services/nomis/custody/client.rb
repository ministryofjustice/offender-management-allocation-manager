require 'faraday'

module Nomis
  module Custody
    class Client
      APIError = Class.new(StandardError)

      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
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
      rescue Faraday::ResourceNotFound => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        raise APIError, "Unexpected status #{e.response[:status]}"
      end

      def token
        Nomis::Oauth::TokenService.valid_token
      end
    end
  end
end
