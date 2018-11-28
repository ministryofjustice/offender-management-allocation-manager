require 'rails_helper'

describe Nomis::Oauth::Client do
  describe 'with a valid request' do
    it 'sets the Authorization header', vcr: { cassette_name: 'nomis_oauth_client_auth_header' } do
      api_host = Rails.configuration.nomis_oauth_host
      route = '/auth/oauth/token?grant_type=client_credentials'
      client = described_class.new(api_host)

      client.get(route)

      expect(WebMock).to have_requested(:get, /\w/).
        with(
          headers: {
            'Authorization': "Basic #{ Rails.configuration.nomis_oauth_authorisation }"
          }
      )
    end
  end

  describe 'when there is an http status header' do
    xit 'raises an APIError' do

    end

    xit 'sends the error to Sentry' do

    end
  end

  describe 'when there is a timeout' do

  end
end
