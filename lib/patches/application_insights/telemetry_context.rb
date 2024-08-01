# frozen_string_literal: true

module Patches
  module ApplicationInsights
    module TelemetryContext
      def initialize
        super

        cloud.role_name = 'offender-management-allocation-manager'
        cloud.role_instance = ENV['HOSTNAME']
      end
    end
  end
end
