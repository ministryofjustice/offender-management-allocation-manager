require 'rails_helper'

describe Allocation::Client do
  describe 'with a valid request' do
    it 'sets the Authorization header', vcr: { cassette_name: 'allocation_client_auth_header' } do
      api_host = Rails.configuration.allocation_api_host
      route = '/status'
      client = described_class.new(api_host)
      token_service = Nomis::Oauth::TokenService
      access_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbnRlcm5hbFVzZXIiOmZhbHNlLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQzNDA1Mjc2LCJhdXRob3JpdGllcyI6WyJST0xFX1NZU1RFTV9SRUFEX09OTFkiXSwianRpIjoiYzgxYzgzNjYtZDk1Ny00ZDdkLWI4MmItNGQ5Mzk2YTBmODFlIiwiY2xpZW50X2lkIjoib2ZmZW5kZXItbWFuYWdlbWVudC1hbGxvY2F0aW9uLW1hbmFnZXIifQ.jPRjMggNhu4LxkY9sGU4cg8WmXnva5UQ9RUpYaMPCqhWE4issL3o0E_ajqH4ToJt0_STStEud9CKDP8PqqV1GECN8xwGfVkCOvFKmcaDjtpGEvCSotge8Cuu8WGfqTtn1f02lgBKV-1j4PD_TM7fkBOVl84UOukWznOXhM4XlUSOkKJ422s8LU496b7VatYNo-0DpKC7e_9slHyH-7t7yydLLdTNl8wzPybFz_2FQ63udoT3BGoA3RmTU6OFN36kk5Plc2-J4WhynFMxdKYMhw5bYXqNsFFcLmaWLyCv4wRDHQvi2JoZ-17SaFgavKaDFEiA58YZyuRcik-HDTn1jQ"
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

  describe 'when there is an http status header' do
    xit 'raises an APIError' do
    end

    xit 'sends the error to Sentry' do
    end
  end

  describe 'when there is a timeout' do
  end
end
