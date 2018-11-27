module Nomis
  module Oauth
    class TokenService
      include Singleton

      def valid_token
        set_new_token if token.expired?
        token
      end

    private

      def set_new_token
        @token = fetch_token
      end

      def token
        @token ||= fetch_token
      end

      def fetch_token
        Nomis::Oauth::Api.instance.fetch_new_auth_token
      end
    end
  end
end
