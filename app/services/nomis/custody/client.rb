require 'faraday'

module Nomis
  APIError = Class.new(StandardError)
  module Custody
    class Client
      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
          faraday.use Faraday::Response::RaiseError
          faraday.adapter Faraday.default_adapter
        end
      end

      def get(route)
        request(:get, route)
      end

    private

      def request(method, route)
        response = @connection.send(method) { |req|
          req.url(@host + route)
          req.headers['Authorization'] = "Bearer #{token.access_token}"
        }

        JSON.parse(response.body)
      rescue Faraday::Error::ClientError => e
        AllocationManager::ExceptionHandler.capture_exception(Nomis::Error::NotFound.new(e))
        NullReleaseDetails.new
      end

      def token
        Nomis::Oauth::TokenService.valid_token
      end
    end
  end
end
