require 'rails_helper'
require 'application_insights'
require 'rack/mock'
require Rails.root.join('lib/patches/application_insights/track_request')

ApplicationInsights::Rack::TrackRequest.prepend(Patches::ApplicationInsights::TrackRequest) unless
  ApplicationInsights::Rack::TrackRequest < Patches::ApplicationInsights::TrackRequest

RSpec.describe ApplicationInsights::Rack::TrackRequest do
  subject(:middleware) do
    described_class.allocate.tap do |instance|
      instance.instance_variable_set(:@app, app)
      instance.instance_variable_set(:@instrumentation_key, 'test-key')
      instance.instance_variable_set(:@client, client)
    end
  end

  let(:app) do
    ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }
  end
  let(:channel) { instance_double(ApplicationInsights::Channel::TelemetryChannel, write: true) }
  let(:client) { instance_double(ApplicationInsights::TelemetryClient, channel:, track_exception: nil) }

  describe '#call' do
    it 'adds the default hmpps user metadata properties to request telemetry' do
      env = Rack::MockRequest.env_for('/prisons/LEI/dashboard').merge(
        'rack.session' => {
          'sso_data' => {
            'staff_id' => 123_456,
            'user_uuid' => '11111111-2222-3333-4444-555555555555',
            'active_caseload' => 'LEI'
          }
        }
      )

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.properties).to eq(
          'userId' => '123456',
          'userUuid' => '11111111-2222-3333-4444-555555555555',
          'activeCaseLoadId' => 'LEI'
        )
      end
    end

    it 'does not track noisy paths' do
      %w[/health /health/ping /info /favicon.ico /assets/styles.css].each do |path|
        env = Rack::MockRequest.env_for(path)

        status, headers, response = middleware.call(env)

        expect(status).to eq(200)
        expect(headers['Content-Type']).to eq('text/plain')
        expect(response).to eq(['ok'])
        expect(channel).not_to have_received(:write)
      end
    end

    it 'omits blank and missing user metadata properties' do
      env = Rack::MockRequest.env_for('/prisons/LEI/dashboard').merge(
        'rack.session' => {
          sso_data: {
            staff_id: nil,
            user_uuid: '',
            active_caseload: 'LEI'
          }
        }
      )

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.properties).to eq(
          'activeCaseLoadId' => 'LEI'
        )
      end
    end

    it 'sends no custom user metadata when the user is not signed in' do
      env = Rack::MockRequest.env_for('/prisons/LEI/dashboard').merge('rack.session' => {})

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.properties).to eq({})
      end
    end
  end
end
