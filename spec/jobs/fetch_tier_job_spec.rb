# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchTierJob, type: :job do
  subject(:job) { described_class.new }

  let(:crn) { 'X362207' }
  let(:nomis_offender_id) { 'G4281GV' }

  describe '#perform' do
    context 'when case_info does not exist' do
      it 'logs a warning and returns early' do
        allow(job.logger).to receive(:warn)

        job.perform(crn)

        expect(job.logger).to have_received(:warn).with(/event=case_info_not_found/)
      end
    end

    context 'when case_info exists' do
      let!(:case_info) do
        create(:case_information,
               crn: crn,
               tier: 'A',
               offender: build(:offender, nomis_offender_id: nomis_offender_id))
      end

      context 'when the Tier API returns nil' do
        before do
          allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3).and_return(nil)
        end

        it 'logs a warning and does not update tier' do
          allow(job.logger).to receive(:warn)

          job.perform(crn)

          expect(job.logger).to have_received(:warn).with(/event=tier_api_failed/)
          expect(case_info.reload.tier).to eq('A')
        end
      end

      context 'when the Tier API returns a blank tier' do
        before do
          allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
            .and_return({ tier: nil, calculation_date: nil })
        end

        it 'logs a warning and does not update tier' do
          allow(job.logger).to receive(:warn)

          job.perform(crn)

          expect(job.logger).to have_received(:warn).with(/event=tier_api_failed/)
        end
      end

      context 'when the Tier API returns the same tier' do
        before do
          allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
            .and_return({ tier: 'A2', calculation_date: Date.current })
        end

        it 'does not update the record' do
          expect { job.perform(crn) }.not_to(change { case_info.reload.updated_at })
        end
      end

      context 'when the Tier API returns a different tier' do
        before do
          allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
            .and_return({ tier: 'B1', calculation_date: Date.current })
        end

        it 'updates the tier' do
          job.perform(crn)

          expect(case_info.reload.tier).to eq('B')
        end

        it 'publishes an audit event' do
          expect {
            job.perform(crn)
          }.to change { AuditEvent.tags('fetch_tier_job').count }.by(1)

          audit_event = AuditEvent.tags('fetch_tier_job').last
          expect(audit_event.data['before']).to eq({ 'tier' => 'A' })
          expect(audit_event.data['after']).to eq({ 'tier' => 'B' })
          expect(audit_event.tags).to include('tier', 'changed')
        end

        it 'logs a success message' do
          allow(job.logger).to receive(:info)

          job.perform(crn)

          expect(job.logger).to have_received(:info).with(/event=tier_updated,old_tier=A,new_tier=B/)
        end
      end

      context 'when the Tier API returns an invalid tier' do
        before do
          allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
            .and_return({ tier: 'Z', calculation_date: Date.current })
        end

        it 'does not update the tier and logs an error' do
          allow(job.logger).to receive(:error)

          job.perform(crn)

          expect(case_info.reload.tier).to eq('A')
          expect(job.logger).to have_received(:error).with(/event=tier_update_failed/)
        end
      end
    end
  end
end
