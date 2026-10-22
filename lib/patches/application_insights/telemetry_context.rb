# frozen_string_literal: true

module Patches
  module ApplicationInsights
    module TelemetryContext
      def initialize
        super

        cloud.role_name = Rails.configuration.service_name
        cloud.role_instance = ENV['HOSTNAME']
        application.ver = ENV['BUILD_NUMBER']
      end
    end
  end
end
