# frozen_string_literal: true

module Patches
  module ApplicationInsights
    module TrackRequest
      IGNORED_PATH_PATTERNS = %w[/info /health /health/ping /favicon.ico /assets/*].freeze

      def call(env)
        return @app.call(env) if ignored_path?(env)

        super
      end

    private

      def options_hash(request)
        super.merge(properties: telemetry_properties(request))
      end

      # See: https://github.com/ministryofjustice/hmpps-typescript-lib/blob/main/packages/azure-telemetry/src/main/middleware/addUserMetadataToTelemetry.ts
      def telemetry_properties(request)
        sso_data = (request.session[:sso_data] || request.session['sso_data'])&.symbolize_keys
        return {} if sso_data.blank?

        {
          'userId' => sso_data[:staff_id],
          'userUuid' => sso_data[:user_uuid],
          'activeCaseLoadId' => sso_data[:active_caseload],
        }.compact_blank.transform_values(&:to_s)
      end

      def ignored_path?(env)
        path = Rack::Request.new(env).path

        IGNORED_PATH_PATTERNS.any? do |pattern|
          if pattern.end_with?('*')
            path.start_with?(pattern.delete_suffix('*'))
          else
            path == pattern
          end
        end
      end
    end
  end
end
