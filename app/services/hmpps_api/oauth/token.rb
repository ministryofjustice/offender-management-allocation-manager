# frozen_string_literal: true

require 'base64'

module HmppsApi
  module Oauth
    class Token
      attr_writer :expires_in,
                  :internal_user,
                  :token_type,
                  :auth_source,
                  :jti

      attr_accessor :access_token,
                    :scope

      def initialize(fields = {})
        # Allow this object to be reconstituted from a hash, we can't use
        # from_json as the one passed in will already be using the snake case
        # names whereas from_json is expecting the elite2 camelcase names.
        fields.each { |k, v| instance_variable_set("@#{k}", v) }

        @expiry_time = Time.zone.now + @expires_in.to_i.seconds
      end

      def needs_refresh?
        # we need to refresh the token just before expiry as it might expire on its way to the API
        @expiry_time - Time.zone.now < 20
      end

      def valid_token_with_scope?(scope, role: nil)
        return false if payload['scope'].nil?
        return false unless payload['scope'].include? scope

        if role && !payload.fetch('authorities', []).include?(role)
          Rails.logger = Logger.new($stdout) if Rails.env.production?

          Rails.logger.error(
            "event=api_access_blocked,token_user_name=#{payload['user_name']},token_client_id=" \
            "#{payload['client_id']},missing_role=#{role}|API access blocked due to missing role"
          )

          return false
        end

        true
      rescue JWT::DecodeError, JWT::ExpiredSignature => e
        Sentry.capture_exception(e)
        false
      end

      def payload
        @payload ||= JwksDecoder.decode_token(access_token).first
      end

      def self.from_json(payload)
        Token.new(payload)
      end
    end
  end
end
