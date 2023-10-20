# frozen_string_literal: true

require 'faraday'
require 'typhoeus/adapters/faraday'

module HmppsApi
  class DpsFrontendComponentsApi
    class << self
      def header(token)
        get_component('header', token)
      end

      def footer(token)
        get_component('footer', token)
      end

    private

      def get_component(type, token)
        raw_response = connection.get do |req|
          req.url("#{root}/#{type}")
          req.headers['X-User-Token'] = token
        end

        ActiveSupport::JSON.decode(raw_response.body)
      end

      def connection
        Faraday.new do |faraday|
          faraday.options.timeout = 3
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
    end
  end
end
