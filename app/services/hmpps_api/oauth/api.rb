# frozen_string_literal: true

module HmppsApi
  module Oauth
    class Api
      include Singleton

      class << self
        delegate :fetch_new_auth_token, :fetch_jwks_keys, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @oauth_client = HmppsApi::Oauth::Client.new(host)
      end

      def fetch_new_auth_token
        route = '/auth/oauth/token?grant_type=client_credentials'
        response = @oauth_client.post(route)

        api_deserialiser.deserialise(HmppsApi::Oauth::Token, response)
      end

      def fetch_jwks_keys
        route = '/auth/.well-known/jwks.json'
        @oauth_client.get(route)
      end

    private

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
