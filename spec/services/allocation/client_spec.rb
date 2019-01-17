require 'rails_helper'

describe Allocation::Client do
  describe 'with a valid request' do
    it 'sets the Authorization header', vcr: { cassette_name: 'allocation_client_auth_header' } do
      api_host = Rails.configuration.allocation_api_host
      route = '/status'
      client = described_class.new(api_host)
      token_service = Nomis::Oauth::TokenService
      access_token = "A random string"
      valid_token = Nomis::Oauth::Token.new(access_token: access_token)

      allow(token_service).to receive(:valid_token).and_return(valid_token)

      WebMock.stub_request(:get, /\w/).to_return(body: '{}')

      client.get(route)

      expect(WebMock).to have_requested(:get, /\w/).
        with(
          headers: {
            'Authorization': "Bearer #{access_token}"
          }
      )
    end
  end
end
