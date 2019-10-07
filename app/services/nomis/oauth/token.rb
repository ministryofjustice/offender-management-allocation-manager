# frozen_string_literal: true

require 'base64'

module Nomis
  module Oauth
    class Token
      include Deserialisable

      attr_accessor :access_token,
                    :token_type,
                    :expires_in,
                    :scope,
                    :internal_user,
                    :jti,
                    :auth_source

      def initialize(fields = nil)
        # Allow this object to be reconstituted from a hash, we can't use
        # from_json as the one passed in will already be using the snake case
        # names whereas from_json is expecting the elite2 camelcase names.
        fields.each { |k, v| instance_variable_set("@#{k}", v) } if fields.present?
      end

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

      def valid_token?
        payload = JWT.decode(
          access_token,
          OpenSSL::PKey::RSA.new(public_key),
          true,
          algorithm: 'RS256'
        )

        return false if payload.first['exp'].nil?

        if payload.first['scope'].nil? || !payload.first['scope'].include?('read')
          return false
        end

        true
      rescue JWT::DecodeError
        false
      end

      def self.from_json(payload)
        Token.new.tap { |obj|
          obj.access_token = payload['access_token']
          obj.token_type = payload['token_type']
          obj.expires_in = payload['expires_in']
          obj.scope = payload['scope']
          obj.internal_user = payload['internal_user']
          obj.jti = payload['jti']
          obj.auth_source = payload['auth_source']
        }
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
