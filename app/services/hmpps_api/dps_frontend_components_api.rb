# frozen_string_literal: true

require 'faraday'
require 'typhoeus/adapters/faraday'

module HmppsApi
  class DpsFrontendComponentsApi
    class << self
      # See: https://frontend-components-dev.hmpps.service.justice.gov.uk/api-docs/#/default/get_components
      def components(token, component: %w[header footer])
        raw_response = connection.get do |req|
          req.url("#{root}/components?#{components_query(Array(component))}")
          req.headers['X-User-Token'] = token
        end

        ActiveSupport::JSON.decode(raw_response.body)
      end

    private

      def components_query(component)
        URI.encode_www_form(component.map { ['component', it] })
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
