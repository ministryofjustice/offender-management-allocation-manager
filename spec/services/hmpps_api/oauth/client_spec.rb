require 'rails_helper'
require 'base64'

describe HmppsApi::Oauth::Client do
  let(:api_host) { Rails.configuration.nomis_oauth_host }
  let(:client) { described_class.new(api_host) }
  let(:route) { '/auth/oauth/token?grant_type=client_credentials' }

  describe 'configuration' do
    it 'uses the shared HMPPS API timeout settings' do
      connection = client.instance_variable_get(:@connection)

      expect(connection.options.open_timeout).to eq(Rails.configuration.hmpps_api_open_timeout_seconds)
      expect(connection.options.timeout).to eq(Rails.configuration.hmpps_api_timeout_seconds)
    end

    it 'configures token POST retries with bounded waits' do
      expect(Faraday::Retry::Middleware).to receive(:new).with(
        anything,
        hash_including(
          max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2, max_interval: 5,
          retry_statuses: [502],
          methods: Faraday::Retry::Middleware::IDEMPOTENT_METHODS + [:post]
        )
      ).and_call_original

      client.post(route)
    end
  end

  context 'with a valid request' do
    it 'sets the Authorization header' do
      client.post(route)

      credentials = "#{Rails.configuration.hmpps_api_client_id}:#{Rails.configuration.hmpps_api_client_secret}"
      expect(WebMock).to have_requested(:post, "#{api_host}#{route}")
        .with(headers: { 'Authorization' => "Basic #{Base64.strict_encode64(credentials)}" })
    end
  end

  describe '#get' do
    it 'returns the decoded JWKS response' do
      stub_request(:get, "#{api_host}/auth/.well-known/jwks.json").to_return(body: '{"keys":[]}')

      expect(client.get('/auth/.well-known/jwks.json')).to eq('keys' => [])
    end
  end

  describe 'request logging' do
    [401, 502].each do |status|
      it "omits credentials and query strings from explicit HTTP #{status} logs" do
        allow(Rails.logger).to receive(:warn)
        route = '/auth/oauth/token?access_token=query-secret'
        stub_request(:post, "#{api_host}#{route}").to_return(status:)

        expect { client.post(route) }.to raise_error(Faraday::Error)
        expect(Rails.logger).not_to have_received(:warn).with(include('query-secret'))
        expect(Rails.logger).not_to have_received(:warn).with(include('Basic '))
      end
    end
  end

  describe 'retry policy' do
    before do
      allow(Rails.logger).to receive(:warn)
    end

    [429, 500].each do |status|
      it "does not retry HTTP #{status} responses" do
        stub_request(:post, "#{api_host}#{route}").to_return(status:)

        expect { client.post(route) }.to raise_error(status < 500 ? Faraday::ClientError : Faraday::ServerError)
        expect(WebMock).to have_requested(:post, "#{api_host}#{route}").once
        expect(Rails.logger).not_to have_received(:warn).with(include('event=hmpps_oauth_retry,'))
      end
    end

    it 'retries a transient 502 on a token POST with the same credentials' do
      stub_request(:post, "#{api_host}#{route}").to_return(status: 502).then
        .to_return(body: '{"access_token":"new_token"}')

      expect(client.post(route)).to eq('access_token' => 'new_token')
      expect(WebMock).to have_requested(:post, "#{api_host}#{route}")
        .with(headers: { 'Authorization' => /^Basic / }).twice
      expect(Rails.logger).to have_received(:warn).with(
        'event=hmpps_oauth_retry,reason=Faraday::RetriableResponse,method=POST,route=/auth/oauth/token,' \
        'status=502,retry_count=0'
      ).once
      expect(Rails.logger).not_to have_received(:warn).with(include('event=hmpps_oauth_request_failed,'))
    end

    it 'propagates and logs a final 502' do
      stub_request(:post, "#{api_host}#{route}").to_return(status: 502)

      expect { client.post(route) }.to raise_error(Faraday::ServerError) { |e| expect(e.response_status).to eq(502) }
      expect(Rails.logger).to have_received(:warn).with(
        'event=hmpps_oauth_request_failed,reason=Faraday::ServerError,method=POST,route=/auth/oauth/token,' \
        'status=502'
      ).once
    end

    it 'retries a read timeout on a token POST with the same credentials' do
      stub_request(:post, "#{api_host}#{route}").to_raise(Faraday::TimeoutError).then
        .to_return(body: '{"access_token":"new_token"}')

      expect(client.post(route)).to eq('access_token' => 'new_token')
      expect(WebMock).to have_requested(:post, "#{api_host}#{route}")
        .with(headers: { 'Authorization' => /^Basic / }).twice
      expect(Rails.logger).to have_received(:warn).with(
        'event=hmpps_oauth_retry,reason=Faraday::TimeoutError,method=POST,route=/auth/oauth/token,' \
        'status=,retry_count=0'
      ).once
    end

    it 'does not retry connection failures' do
      stub_request(:post, "#{api_host}#{route}").to_raise(Faraday::ConnectionFailed)

      expect { client.post(route) }.to raise_error(Faraday::ConnectionFailed)
      expect(WebMock).to have_requested(:post, "#{api_host}#{route}").once
      expect(Rails.logger).to have_received(:warn).with(
        include('event=hmpps_oauth_request_failed,reason=Faraday::ConnectionFailed,')
      ).once
    end

    it 'does not retry rejected credentials' do
      stub_request(:post, "#{api_host}#{route}").to_return(status: 401)

      expect { client.post(route) }.to raise_error(Faraday::UnauthorizedError)
      expect(WebMock).to have_requested(:post, "#{api_host}#{route}").once
      expect(Rails.logger).to have_received(:warn).with(
        include('event=hmpps_oauth_request_failed,reason=Faraday::UnauthorizedError,', 'status=401')
      ).once
    end
  end
end
