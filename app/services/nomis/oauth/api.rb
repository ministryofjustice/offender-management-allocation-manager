module Nomis
  module Oauth
    class Api
      include Singleton

      def fetch_new_auth_token
        response = Faraday.post { |req|
          req.url "#{Rails.configuration.nomis_oauth_url}/auth/oauth/token?grant_type=client_credentials"
          req.headers['Authorization'] = "Basic #{Rails.configuration.nomis_oauth_authorisation}"
        }

        access_token = JSON.parse(response.body)['access_token']

        Nomis::Oauth::Token.new(access_token)
      end
    end
  end
end
