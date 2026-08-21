require 'rails_helper'
require 'base64'

describe HmppsApi::Oauth::Client do
  let(:api_host) { Rails.configuration.nomis_oauth_host }
  let(:client) { described_class.new(api_host) }
  let(:route) { '/auth/oauth/token?grant_type=client_credentials' }

  describe 'timeout configuration' do
    it 'uses the shared HMPPS API timeout settings' do
      connection = client.instance_variable_get(:@connection)

      expect(connection.options.open_timeout).to eq(Rails.configuration.hmpps_api_open_timeout_seconds)
      expect(connection.options.timeout).to eq(Rails.configuration.hmpps_api_timeout_seconds)
    end
  end

  context 'with a valid request' do
    it 'sets the Authorization header' do
      client.post(route)

      expect(WebMock).to have_requested(:post, "#{api_host}#{route}").with(headers: { 'Authorization': /^Basic .*/ })
    end

    context 'when a HTTP error response is received' do
      before do
        WebMock.stub_request(:post, /\w/)
            .to_return(status: status)
      end

      describe 'a 5xx error' do
        let(:status) { 504 }

        it 'raises the correct error' do
          expect { client.post(route) }
              .to raise_error(Faraday::ServerError, "the server responded with status #{status}")
        end
      end
    end
  end
end
