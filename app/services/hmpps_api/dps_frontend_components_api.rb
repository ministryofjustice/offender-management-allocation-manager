# frozen_string_literal: true

require 'faraday'
require 'typhoeus/adapters/faraday'

module HmppsApi
  class DpsFrontendComponentsApi
    class << self
      def footer
        raw_response = connection.get do |req|
          req.url("#{root}/footer")
          req.headers['x-user-token'] = token.access_token
        end

        ActiveSupport::JSON.decode(raw_response.body)
      end

    private

      def connection
        Faraday.new do |faraday|
          faraday.options.params_encoder = Faraday::FlatParamsEncoder
          faraday.request :instrumentation
          # Response middleware is supposed to be registered after request middleware
          faraday.response :raise_error
          faraday.adapter :typhoeus
        end
      end

      def root
        Rails.configuration.dps_frontend_components_api_host
      end

      def token
        HmppsApi::Oauth::TokenService.valid_token
      end
    end
  end
end
