require 'rails_helper'

describe Nomis::Custody::Client do
  describe 'with a valid request' do
    around do |example|
      travel_to Date.new(2018, 12, 9, 17) do
        example.run
      end
    end

    it 'sets the Authorization header', vcr: { cassette_name: 'custodyapi_client_auth_header' } do
      api_host = Rails.configuration.nomis_oauth_host
      username = 'PK000223'
      route = "/custodyapi/api/nomis-staff-users/#{username}"
      client = described_class.new(api_host)
      token_service = Nomis::Oauth::TokenService
      access_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbnRlcm5hbFVzZXIiOmZhbHNlLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ0MzgzNzM4LCJhdXRob3JpdGllcyI6WyJST0xFX1NZU1RFTV9SRUFEX09OTFkiXSwianRpIjoiMjI3NGQ3ZDctM2QzYi00NmRhLTg0NGMtM2Y3Yzc2YmVkNDJiIiwiY2xpZW50X2lkIjoib2ZmZW5kZXItbWFuYWdlbWVudC1hbGxvY2F0aW9uLW1hbmFnZXIifQ.BKYcKggL1JE1vFbrF0-absKolbfzXRmQwy_k3wIPntCVaTWGlVVUk_0r9FS9Okrle26mTfZ-DPD_vus5m6Jto7mj2On6j_zqhx1Eae7pbcgji1yU_e5cO-Oo0JcoqDZZPzcbiypZ-AMbh9iBFBcYYbg0UsfQnknTob48i9-p_PDTWX4sdRWEwSRn71xAewfaSWEvg4tMdZW0js6gti9K4iEEbEdAktM1eUT4woqbvOFURjOVXaD4F-qTF1Fb5adgoWdp63KbSkz4lWzQN5l6Qka1XekZoi0jgw1WLE-DnHU_v888Ft736BQQo9Wa4egHf4ERMagsxkyCen2OCcbCAg"
      valid_token = Nomis::Oauth::Token.new(access_token)

      allow(token_service).to receive(:valid_token).and_return(valid_token)

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
