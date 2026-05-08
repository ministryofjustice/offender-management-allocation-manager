require 'rails_helper'
require 'application_insights'
require Rails.root.join('lib/patches/application_insights/telemetry_client')

ApplicationInsights::TelemetryClient.prepend(Patches::ApplicationInsights::TelemetryClient) unless
  ApplicationInsights::TelemetryClient < Patches::ApplicationInsights::TelemetryClient

RSpec.describe ApplicationInsights::TelemetryClient do
  subject(:client) { described_class.new('test-key', channel) }

  let(:channel) { instance_double(ApplicationInsights::Channel::TelemetryChannel, write: true) }

  describe '#track_exception' do
    let(:exception) do
      StandardError.new('boom').tap do |error|
        error.set_backtrace(['app/views/example.html.erb:1'])
      end
    end

    it 'does not send exception telemetry to Application Insights' do
      expect(client.track_exception(exception, handled_at: 'Unhandled')).to be_nil
      expect(channel).not_to have_received(:write)
    end
  end
end
