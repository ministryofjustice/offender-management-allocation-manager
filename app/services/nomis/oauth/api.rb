module Nomis
  module Oauth
    class Api
      include Singleton

      def fetch_auth_token
        response = Faraday.post do |req|
          req.url "#{Rails.configuration.nomis_oauth_url}/auth/oauth/token?grant_type=client_credentials"
          req.headers["Authorization"] = "Basic #{Rails.configuration.nomis_oauth_authorisation}"
        end

        response_body = JSON.parse(response.body)
        Nomis::Oauth::Token.new(response_body)
      end
    end
  end
end
