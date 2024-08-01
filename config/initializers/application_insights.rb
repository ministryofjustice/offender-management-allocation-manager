# frozen_string_literal: true

Rails.application.configure do
  if (key = ENV['APPINSIGHTS_INSTRUMENTATIONKEY'].presence)
    require 'application_insights'

    # Add additional context tags (the gem does not support this out of the box)
    require 'patches/application_insights/telemetry_context'
    ApplicationInsights::Channel::TelemetryContext.prepend Patches::ApplicationInsights::TelemetryContext

    config.middleware.use(
      ApplicationInsights::Rack::TrackRequest, key
    )
  end
end
