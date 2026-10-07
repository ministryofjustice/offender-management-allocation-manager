require 'rails_helper'
require 'application_insights'
require Rails.root.join('lib/patches/application_insights/telemetry_context')

ApplicationInsights::Channel::TelemetryContext.prepend(Patches::ApplicationInsights::TelemetryContext) unless
  ApplicationInsights::Channel::TelemetryContext < Patches::ApplicationInsights::TelemetryContext

RSpec.describe ApplicationInsights::Channel::TelemetryContext do
  describe '#initialize' do
    it 'sets service role, role instance, and application version metadata' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HOSTNAME').and_return('test-host')
      allow(ENV).to receive(:[]).with('BUILD_NUMBER').and_return('0afbc7')

      context = described_class.new

      expect(context.cloud.role_name).to eq('offender-management-allocation-manager')
      expect(context.cloud.role_instance).to eq('test-host')
      expect(context.application.ver).to eq('0afbc7')
    end
  end
end
