module Nomis
  module Oauth
    class Token
      attr_reader :encrypted_token

      def initialize(encrypted_token)
        @encrypted_token = encrypted_token
      end

      def expired?
        JWT.decode(
          encrypted_token,
          Rails.configuration.nomis_oauth_public_key,
          true,
          algorithm: 'RS256'
        )
        false
      rescue JWT::ExpiredSignature
        true
      end
    end
  end
end
