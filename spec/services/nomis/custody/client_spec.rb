require 'rails_helper'

describe Nomis::Custody::Client do
  let(:api_host) { Rails.configuration.nomis_oauth_host }
  let(:client) { described_class.new(api_host) }
  let(:token_service) { Nomis::Oauth::TokenService }
  let(:access_token) { "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbnRlcm5hbFVzZXIiOmZhbHNlLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQ0MzgzNzM4LCJhdXRob3JpdGllcyI6WyJST0xFX1NZU1RFTV9SRUFEX09OTFkiXSwianRpIjoiMjI3NGQ3ZDctM2QzYi00NmRhLTg0NGMtM2Y3Yzc2YmVkNDJiIiwiY2xpZW50X2lkIjoib2ZmZW5kZXItbWFuYWdlbWVudC1hbGxvY2F0aW9uLW1hbmFnZXIifQ.BKYcKggL1JE1vFbrF0-absKolbfzXRmQwy_k3wIPntCVaTWGlVVUk_0r9FS9Okrle26mTfZ-DPD_vus5m6Jto7mj2On6j_zqhx1Eae7pbcgji1yU_e5cO-Oo0JcoqDZZPzcbiypZ-AMbh9iBFBcYYbg0UsfQnknTob48i9-p_PDTWX4sdRWEwSRn71xAewfaSWEvg4tMdZW0js6gti9K4iEEbEdAktM1eUT4woqbvOFURjOVXaD4F-qTF1Fb5adgoWdp63KbSkz4lWzQN5l6Qka1XekZoi0jgw1WLE-DnHU_v888Ft736BQQo9Wa4egHf4ERMagsxkyCen2OCcbCAg" }
  let(:valid_token) { Nomis::Oauth::Token.new(access_token: access_token) }

  before do
    allow(token_service).to receive(:valid_token).and_return(valid_token)
  end

  describe 'with a valid request' do
    it 'sets the Authorization header', vcr: { cassette_name: 'custodyapi_client_auth_header' } do
      username = 'PK000223'
      route = "/custodyapi/api/nomis-staff-users/#{username}"
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
    let(:booking_id)  { '987653' }
    let(:path)        { "/custodyapi/api/offenders/offenderId/#{offender_id}/releaseDetails?bookingId=#{booking_id}" }

    before do
      WebMock.stub_request(:get, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      expect { client.get(path) }.
        to raise_error(Nomis::Custody::Client::APIError, 'Unexpected status 401')
    end

    it 'sends the error to sentry' do
      expect(AllocationManager::ExceptionHandler).to receive(:capture_exception).with(error)
      expect { client.get(path) }.to raise_error(Nomis::Custody::Client::APIError)
    end
  end

  describe 'when there is an 500 (server broken) error' do
    let(:error) do
      Faraday::ClientError.new('error', status: 500)
    end
    let(:offender_id) { '12344556' }
    let(:booking_id)  { '987653' }
    let(:path)        { "/custodyapi/api/offenders/offenderId/#{offender_id}/releaseDetails?bookingId=#{booking_id}" }

    before do
      WebMock.stub_request(:get, /\w/).to_raise(error)
    end

    it 'raises an APIError', :raven_intercept_exception do
      expect { client.get(path) }.
        to raise_error(Nomis::Custody::Client::APIError, 'Unexpected status 500')
    end

    it 'sends the error to sentry' do
      expect(AllocationManager::ExceptionHandler).to receive(:capture_exception).with(error)
      expect { client.get(path) }.to raise_error(Nomis::Custody::Client::APIError)
    end
  end
end
