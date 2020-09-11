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
    subject {
      described_class.set_handover_dates(
        offender_no: offender_no,
        handover_start_date: handover_start_date,
        responsibility_handover_date: responsibility_handover_date
      )
    }

    let(:stub_base_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/custody/keyDates" }

    before do
      stub_request(:put, "#{stub_base_url}/POM1").to_return(status: 200, body: '{}')
      stub_request(:put, "#{stub_base_url}/POM2").to_return(status: 200, body: '{}')
      stub_request(:delete, "#{stub_base_url}/POM1").to_return(status: 200)
      stub_request(:delete, "#{stub_base_url}/POM2").to_return(status: 200)

      # Trigger the request
      subject
    end

    describe 'when both handover dates are given' do
      let(:handover_start_date) { Date.parse('01/02/2020') }
      let(:responsibility_handover_date) { Date.parse('18/10/2020') }

      it 'sets both handover dates for the given offender' do
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

    describe 'when both the dates are nil' do
      let(:handover_start_date) { nil }
      let(:responsibility_handover_date) { nil }

      it 'deletes both dates for the given offender' do
        # Handover start date = POM1
        expect(WebMock).to have_requested(:delete, "#{stub_base_url}/POM1")

        # Responsibility handover date = POM2
        expect(WebMock).to have_requested(:delete, "#{stub_base_url}/POM2")
      end
    end

    describe 'when handover start date is nil' do
      let(:handover_start_date) { nil }
      let(:responsibility_handover_date) { Date.parse('25/12/2021') }

      it 'deletes handover start date' do
        # Handover start date = POM1
        expect(WebMock).to have_requested(:delete, "#{stub_base_url}/POM1")
      end

      it 'still sets responsibility handover date' do
        # Responsibility handover date = POM2
        expect(WebMock).to have_requested(:put, "#{stub_base_url}/POM2").
          with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2021-12-25' }.to_json
          )
      end
    end

    describe 'when responsibility handover date is nil' do
      let(:handover_start_date) { Date.parse('01/12/2021') }
      let(:responsibility_handover_date) { nil }

      it 'still sets handover start date' do
        # Handover start date = POM1
        expect(WebMock).to have_requested(:put, "#{stub_base_url}/POM1").
          with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2021-12-01' }.to_json
          )
      end

      it 'deletes responsibility handover date' do
        # Responsibility handover date = POM2
        expect(WebMock).to have_requested(:delete, "#{stub_base_url}/POM2")
      end
    end
  end
end
