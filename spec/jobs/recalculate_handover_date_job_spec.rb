# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecalculateHandoverDateJob, type: :job do
  let(:offender_no) { nomis_offender.fetch(:offenderNo) }
  let(:today) { Time.zone.now }
  let(:prison) { build(:prison) }

  before do
    stub_auth_token
  end

  context "when the offender exists in both NOMIS and nDelius (happy path)" do
    before do
      stub_offender(nomis_offender)
      create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS', manual_entry: false)
    end

    let(:nomis_offender) { build(:nomis_offender) }

    it "recalculates the offender's handover dates and pushes them to the Community API" do
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

    let(:nomis_offender) { build(:nomis_offender) }

    it 'does nothing' do
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
      expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
      described_class.perform_now(offender_no)
    end
  end

  context 'when the Prison API returns an error' do
    let(:nomis_offender) { build(:nomis_offender) }
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

  describe 're-calculation' do
    let!(:case_info) { create(:case_information, :nps, nomis_offender_id: offender_no) }
    let(:offender) { OffenderService.get_offender(offender_no) }

    before do
      stub_offender(nomis_offender)
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
    end

    context "when calculated handover dates don't exist yet for the offender" do
      let(:record) { case_info.calculated_handover_date }
      let(:nomis_offender) { build(:nomis_offender) }

      it 'creates a new record' do
        expect {
          described_class.perform_now(offender_no)
        }.to change(CalculatedHandoverDate, :count).by(1)

        expect(record.start_date).to eq(offender.handover_start_date)
        expect(record.handover_date).to eq(offender.responsibility_handover_date)
        expect(record.reason).to eq(offender.handover_reason)
      end
    end

    context 'when calculated handover dates already exist for the offender' do
      let(:nomis_offender) { build(:nomis_offender) }
      let!(:existing_record) {
        create(:calculated_handover_date,
               case_information: case_info,
               start_date: existing_start_date,
               handover_date: existing_handover_date,
               reason: existing_reason
        )
      }

      describe 'when the dates have changed' do
        let(:existing_start_date) { today + 1.week }
        let(:existing_handover_date) { existing_start_date + 7.months }
        let(:existing_reason) { 'CRC Case' }

        it 'updates the existing record' do
          described_class.perform_now(offender_no)

          existing_record.reload
          expect(existing_record.start_date).to eq(offender.handover_start_date)
          expect(existing_record.handover_date).to eq(offender.responsibility_handover_date)
          expect(existing_record.reason).to eq(offender.handover_reason)
        end
      end

      describe "when the dates haven't changed" do
        let(:existing_start_date) { offender.handover_start_date }
        let(:existing_handover_date) { offender.responsibility_handover_date }
        let(:existing_reason) { offender.handover_reason }

        it "does nothing" do
          old_updated_at = existing_record.updated_at

          travel_to(Time.zone.now + 15.minutes) do
            described_class.perform_now(offender_no)
          end

          new_updated_at = existing_record.reload.updated_at
          expect(new_updated_at).to eq(old_updated_at)
        end
      end
    end
  end
end
