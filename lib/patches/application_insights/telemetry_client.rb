# frozen_string_literal: true

module Patches
  module ApplicationInsights
    module TelemetryClient
      def track_exception(_exception, _options = {})
        nil
      end
    end
  end
end
