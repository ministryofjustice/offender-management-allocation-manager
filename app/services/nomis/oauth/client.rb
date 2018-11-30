module Nomis
  module Oauth
    class Client
      def initialize(host)
        @host = host
        @connection = Faraday.new
      end

      def get(route)
        request(:get, route)
      end

      def post(route)
        request(:post, route)
      end

    private

      def request(method, route)
        response = @connection.send(method) { |req|
          req.url(@host + route)
          req.headers['Authorization'] =
            "Basic #{Rails.configuration.nomis_oauth_authorisation}"
        }

        JSON.parse(response.body)
      end
    end
  end
end
