require "rails_helper"

describe "Health endpoinds" do
  describe "GET /health" do
    it "returns health check status and information regarding the deployed application" do
      new_env = ENV.to_hash.merge(
        'GIT_REF' => 'bf83a70609706cb7fa69f75962f54b0fd71dcf6c',
        'BUILD_NUMBER' => '2014-12-25.0afbc7.af79nbc',
      )
      stub_const('ENV', new_env)
      Rails.configuration.uptime_timer = double("Timer", elapsed_seconds: 999)
      Rails.configuration.health_checks = double("Health", status: { status: "UP" })

      get "/health"

      expect(JSON.parse(response.body)).to eq({
        status: "UP",
        uptime: 999,
        build: {
          'buildNumber' => '2014-12-25.0afbc7.af79nbc',
          'gitRef' => 'bf83a70609706cb7fa69f75962f54b0fd71dcf6c'
        },
        version: '2014-12-25.0afbc7.af79nbc'
      }.deep_stringify_keys)
    end
  end

  describe "GET /health/ping" do
    it 'returns pong' do
      get "/health/ping"
      expect(response.body).to eq('pong')
    end
  end
end
