require 'rails_helper'
require 'base64'

describe Nomis::Oauth::Client do
  describe 'with a valid request' do
    it 'sets the Authorization header', vcr: { cassette_name: 'nomis_oauth_client_auth_header' } do
      api_host = Rails.configuration.nomis_oauth_host
      route = '/auth/oauth/token?grant_type=client_credentials'
      client = described_class.new(api_host)

      client.post(route)

      expect(WebMock).to have_requested(:post, /\w/).
        with(
          headers: {
            'Authorization': 'Basic ' + Base64.urlsafe_encode64(
              "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
            )
          }
      )
    end
  end
end
