require 'rails_helper'

describe Nomis::Elite2::CommunityApi do
  let(:api_host) { Rails.configuration.community_api_host }
  let(:offender_no) { 'A1234BC' }

  before do
    stub_auth_token
  end

  describe '.set_pom' do
    let(:stub_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/prisonOffenderManager" }

    before do
      stub_request(:put, stub_url).to_return(status: 200, body: '{}')
    end

    it 'sets the POM name for the given offender' do
      described_class.set_pom(
        offender_no: offender_no,
        prison: 'PVI',
        forename: 'Jane',
        surname: 'Doe'
      )

      expect_body = {
        nomsPrisonInstitutionCode: 'PVI',
        officer: {
          forenames: 'Jane',
          surname: 'Doe'
        }
      }

      expect(WebMock).to have_requested(:put, stub_url).
        with(
          headers: { 'Content-Type': 'application/json' },
          body: expect_body.to_json
        )
    end
  end

  describe '.set_handover_dates' do
    let(:stub_base_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/custody/keyDates" }

    before do
      stub_request(:put, "#{stub_base_url}/POM1").to_return(status: 200, body: '{}')
      stub_request(:put, "#{stub_base_url}/POM2").to_return(status: 200, body: '{}')
    end

    it 'sets both handover dates for the given offender' do
      described_class.set_handover_dates(
        offender_no: offender_no,
        handover_start_date: Date.parse('01/02/2020'),
        responsibility_handover_date: Date.parse('18/10/2020')
      )

      # Handover start date = POM1
      expect(WebMock).to have_requested(:put, "#{stub_base_url}/POM1").
        with(
          headers: { 'Content-Type': 'application/json' },
          body: { date: '2020-02-01' }.to_json
        )

      # Responsibility handover date = POM2
      expect(WebMock).to have_requested(:put, "#{stub_base_url}/POM2").
        with(
          headers: { 'Content-Type': 'application/json' },
          body: { date: '2020-10-18' }.to_json
        )
    end
  end
end
