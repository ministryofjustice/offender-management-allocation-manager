require 'rails_helper'

describe Allocation::Client do
  let(:api_host) { Rails.configuration.nomis_oauth_host }
  let(:client) { described_class.new(api_host) }
  let(:token_service) { Nomis::Oauth::TokenService }
  let(:access_token) { "access_token" }
  let(:valid_token) { Nomis::Oauth::Token.new(access_token: access_token) }

  before do
    allow(token_service).to receive(:valid_token).and_return(valid_token)
  end

  describe 'with a valid request' do
    it 'sets the Authorization header' do
      path = '/status'

      allow(token_service).to receive(:valid_token).and_return(valid_token)

      WebMock.stub_request(:get, /\w/).to_return(body: '{}')

      client.get(path)

      expect(WebMock).to have_requested(:get, /\w/).
        with(
          headers: {
            'Authorization': "Bearer #{access_token}"
          }
      )
    end
  end

  describe 'when there is an 500 (server broken) error' do
    let(:error) do
      Faraday::ClientError.new('error', status: 500)
    end
    let(:route)   { "/allocation" }
    let(:body) {
      {
        'staff_no' => '1234567',
        'offender_no' => 'A1234AB',
        'offender_id' => '65677888',
        'prison' => 'Leeds',
        'reason' => 'Why not?',
        'notes' => 'Blah',
        'email' => 'pom@pompom.com'
      }
    }

    before do
      WebMock.stub_request(:post, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      expect { client.post(route, body: body) }.
        to raise_error(Allocation::Client::APIError, 'Unexpected status 500')
    end

    it 'sends the error to sentry' do
      expect(AllocationManager::ExceptionHandler).to receive(:capture_exception).with(error)
      expect { client.post(route, body: body) }.to raise_error(Allocation::Client::APIError)
    end
  end
end
