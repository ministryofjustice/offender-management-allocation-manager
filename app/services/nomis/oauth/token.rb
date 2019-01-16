require 'base64'

module Nomis
  module Oauth
    class Token
      include MemoryModel

      attribute :access_token, :string
      attribute :token_type, :string
      attribute :timestamp, :string
      attribute :expires_in, :string
      attribute :scope, :string
      attribute :internal_user, :string
      attribute :jti, :string

      def expired?
        JWT.decode(
          access_token,
          OpenSSL::PKey::RSA.new(public_key),
          true,
          algorithm: 'RS256'
        )
        false
      rescue JWT::ExpiredSignature => e
        Raven.capture_exception(e)
        true
      end

    private

      def public_key
        @public_key ||= Base64.urlsafe_decode64(
          Rails.configuration.nomis_oauth_public_key
        )
      end
    end
  end
end
