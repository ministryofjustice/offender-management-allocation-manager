require 'rails_helper'

describe Nomis::Client do
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
      WebMock.stub_request(:get, /\w/).to_return(body: '{}')

      username = 'PK000223'
      route = "/elite2api/api/users/#{username}"
      client.get(route)

      expect(WebMock).to have_requested(:get, /\w/).
        with(
          headers: {
            'Authorization': "Bearer #{access_token}"
          }
      )
    end
  end

  describe 'when there is an 404 (missing resource) error' do
    let(:error) do
      Faraday::ResourceNotFound.new('error', status: 401)
    end
    let(:offender_id) { '12344556' }
    let(:offender_no) { 'A1234AB' }
    let(:route)        {  "/elite2api/api/prisoners/#{offender_no}" }

    before do
      WebMock.stub_request(:get, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      expect { client.get(route) }.
        to raise_error(Nomis::Client::APIError, 'Unexpected status 401')
    end

    it 'sends the error to sentry' do
      expect(AllocationManager::ExceptionHandler).to receive(:capture_exception).with(error)
      expect { client.get(route) }.to raise_error(Nomis::Client::APIError)
    end
  end

  describe 'when there is an 500 (server broken) error' do
    let(:error) do
      Faraday::ClientError.new('error', status: 500)
    end
    let(:offender_no) { 'A1234AB' }
    let(:route)        { "/elite2api/api/prisoners/#{offender_no}" }

    before do
      WebMock.stub_request(:get, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      expect { client.get(route) }.
        to raise_error(Nomis::Client::APIError, 'Unexpected status 500')
    end

    it 'sends the error to sentry' do
      expect(AllocationManager::ExceptionHandler).to receive(:capture_exception).with(error)
      expect { client.get(route) }.to raise_error(Nomis::Client::APIError)
    end
  end

  describe 'when the server is unreachable' do
    let(:error) do
      Faraday::ConnectionFailed.new('cannot connect')
    end
    let(:route)        { "/" }

    before do
      WebMock.stub_request(:get, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      broken_client = described_class.new('nosuchhost')

      expect { broken_client.get(route) }.
        to raise_error(Nomis::Client::APIError, 'Failed to connect to nosuchhost')
    end
  end
end
