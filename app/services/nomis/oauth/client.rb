require 'base64'

module Nomis
  module Oauth
    class Client
      def initialize(host)
        @host = host
        @connection = Faraday.new
      end

      def post(route)
        request(:post, route)
      end

    private

      def request(method, route)
        response = @connection.send(method) { |req|
          req.url(@host + route)
          req.headers['Authorization'] =
            'Basic ' + authorisation
        }

        JSON.parse(response.body)
      end

      # rubocop:disable Metrics/LineLength
      def authorisation
        Base64.urlsafe_encode64(
          "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
        )
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
