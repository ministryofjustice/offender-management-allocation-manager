# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::CommunityApi do
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

      expect(WebMock).to have_requested(:put, stub_url)
        .with(
          headers: { 'Content-Type': 'application/json' },
          body: expect_body.to_json
        )
    end
  end

  describe '.unset_pom' do
    describe 'when pom name is nil' do
      let(:stub_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/prisonOffenderManager" }

      before do
        stub_request(:delete, stub_url).to_return(status: 200)
      end

      it 'deletes the POM name for the given offender' do
        described_class.unset_pom(offender_no)

        expect(WebMock).to have_requested(:delete, stub_url)
      end
    end
  end

  describe '.set_handover_dates' do
    let(:stub_base_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/custody/keyDates" }

    let(:start_date_url) { "#{stub_base_url}/#{described_class::KeyDate::HANDOVER_START_DATE}" }
    let(:handover_date_url) { "#{stub_base_url}/#{described_class::KeyDate::RESPONSIBILITY_HANDOVER_DATE}" }

    before do
      stub_request(:put, start_date_url).to_return(status: 200, body: '{}')
      stub_request(:put, handover_date_url).to_return(status: 200, body: '{}')
      stub_request(:delete, start_date_url).to_return(status: 200)
      stub_request(:delete, handover_date_url).to_return(status: 200)

      # Trigger the request
      described_class.set_handover_dates(
        offender_no: offender_no,
        handover_start_date: handover_start_date,
        responsibility_handover_date: responsibility_handover_date
      )
    end

    describe 'when both handover dates are given' do
      let(:handover_start_date) { Date.parse('01/02/2020') }
      let(:responsibility_handover_date) { Date.parse('18/10/2020') }

      it 'sets both handover dates for the given offender' do
        # Handover start date
        expect(WebMock).to have_requested(:put, start_date_url)
          .with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2020-02-01' }.to_json
          )

        # Responsibility handover date
        expect(WebMock).to have_requested(:put, handover_date_url)
          .with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2020-10-18' }.to_json
          )
      end
    end

    describe 'when both the dates are nil' do
      let(:handover_start_date) { nil }
      let(:responsibility_handover_date) { nil }

      it 'deletes both dates for the given offender' do
        # Handover start date
        expect(WebMock).to have_requested(:delete, start_date_url)

        # Responsibility handover date
        expect(WebMock).to have_requested(:delete, handover_date_url)
      end
    end

    describe 'when handover start date is nil' do
      let(:handover_start_date) { nil }
      let(:responsibility_handover_date) { Date.parse('25/12/2021') }

      it 'deletes handover start date' do
        # Handover start date
        expect(WebMock).to have_requested(:delete, start_date_url)
      end

      it 'still sets responsibility handover date' do
        # Responsibility handover date
        expect(WebMock).to have_requested(:put, handover_date_url)
          .with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2021-12-25' }.to_json
          )
      end
    end

    describe 'when responsibility handover date is nil' do
      let(:handover_start_date) { Date.parse('01/12/2021') }
      let(:responsibility_handover_date) { nil }

      it 'still sets handover start date' do
        # Handover start date
        expect(WebMock).to have_requested(:put, start_date_url)
          .with(
            headers: { 'Content-Type': 'application/json' },
            body: { date: '2021-12-01' }.to_json
          )
      end

      it 'deletes responsibility handover date' do
        # Responsibility handover date
        expect(WebMock).to have_requested(:delete, handover_date_url)
      end
    end
  end

  describe 'Date type codes' do
    describe 'Handover start date' do
      it 'is "POM1"' do
        expect(described_class::KeyDate::HANDOVER_START_DATE).to eq('POM1')
      end
    end

    describe 'Responsibility handover date' do
      it 'is "POM2"' do
        expect(described_class::KeyDate::RESPONSIBILITY_HANDOVER_DATE).to eq('POM2')
      end
    end
  end
end
