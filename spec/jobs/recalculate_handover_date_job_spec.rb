require 'rails_helper'

RSpec.describe RecalculateHandoverDateJob, type: :job do
  let(:nomis_offender) { build(:nomis_offender) }
  let(:offender_no) { nomis_offender.fetch(:offenderNo) }

  before do
    stub_auth_token
  end

  context "when the offender exists in both NOMIS and nDelius (happy path)" do
    before do
      stub_offender(nomis_offender)
      create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS', manual_entry: false)
    end

    it "recalculates the offender's handover dates" do
      expect(CalculatedHandoverDate).to receive(:recalculate_for) do |received_offender|
        expect(received_offender.offender_no).to eq(offender_no)
      end
      described_class.perform_now(offender_no)
    end

    it "pushes them to the Community API" do
      offender = OffenderService.get_offender(offender_no)

      expect(HmppsApi::CommunityApi).to receive(:set_handover_dates).
        with(offender_no: offender_no,
             handover_start_date: offender.handover_start_date,
             responsibility_handover_date: offender.responsibility_handover_date
        )

      described_class.perform_now(offender_no)
    end
  end

  context "when the offender doesn't exist in NOMIS" do
    before do
      stub_non_existent_offender(offender_no)
    end

    it 'does nothing' do
      expect(CalculatedHandoverDate).not_to receive(:recalculate_for)
      expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
      described_class.perform_now(offender_no)
    end
  end

  context "when the offender doesn't have a sentence in NOMIS" do
    let(:nomis_offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, :unsentenced)) }

    before do
      stub_offender(nomis_offender)
      create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS')
    end

    it 'does nothing' do
      expect(CalculatedHandoverDate).not_to receive(:recalculate_for)
      expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
      described_class.perform_now(offender_no)
    end
  end

  context 'when the Prison API returns an error' do
    let(:api_host) { Rails.configuration.prison_api_host }
    let(:stub_url) { "#{api_host}/api/prisoners/#{offender_no}" }
    let(:status) { 502 }

    before do
      stub_offender(nomis_offender)
      create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS', manual_entry: false)

      # Stub HTTP requests to the Prison API
      stub_request(:any, stub_url).to_return(status: status)
    end

    it 'raises an exception so the job will go into the retry queue' do
      expect {
        described_class.perform_now(offender_no)
      }.to raise_error(Faraday::Error)
    end
  end

  context 'when the Community API returns an error' do
    let(:api_host) { Rails.configuration.community_api_host }
    let(:stub_base_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/custody/keyDates" }
    let(:start_date_url) { "#{stub_base_url}/#{HmppsApi::CommunityApi::KeyDate::HANDOVER_START_DATE}" }
    let(:handover_date_url) { "#{stub_base_url}/#{HmppsApi::CommunityApi::KeyDate::RESPONSIBILITY_HANDOVER_DATE}" }
    let(:status) { nil }

    before do
      stub_offender(nomis_offender)
      create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS', manual_entry: false)

      # Stub HTTP requests to the Community API
      stub_request(:any, start_date_url).to_return(status: status)
      stub_request(:any, handover_date_url).to_return(status: status)
    end

    describe 'HTTP 400: offender has multiple active custodial events' do
      let(:status) { 400 }

      it 'rescues the error to stop the job going into the retry queue' do
        expect {
          described_class.perform_now(offender_no)
        }.not_to raise_error
      end
    end

    describe 'HTTP 409: multiple offenders with the same NOMIS ID exist in nDelius' do
      let(:status) { 409 }

      it 'rescues the error to stop the job going into the retry queue' do
        expect {
          described_class.perform_now(offender_no)
        }.not_to raise_error
      end
    end
  end
end
