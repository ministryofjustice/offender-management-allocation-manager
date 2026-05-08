# frozen_string_literal: true

Rails.application.configure do
  if (key = ENV['APPINSIGHTS_INSTRUMENTATIONKEY'].presence)
    require 'application_insights'

    # Add additional context tags (the gem does not support this out of the box)
    require 'patches/application_insights/telemetry_context'
    ApplicationInsights::Channel::TelemetryContext.prepend Patches::ApplicationInsights::TelemetryContext

    # Disable Application Insights exception reporting and rely on Sentry instead,
    # because the upstream gem's parser is not compatible with our Ruby/Rails versions.
    require 'patches/application_insights/telemetry_client'
    ApplicationInsights::TelemetryClient.prepend Patches::ApplicationInsights::TelemetryClient

    config.middleware.use(
      ApplicationInsights::Rack::TrackRequest, key
    )
  end
end
