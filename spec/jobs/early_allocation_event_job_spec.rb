require 'rails_helper'

RSpec.describe EarlyAllocationEventJob, type: :job do
  let(:prison) { create(:prison) }
  let(:offender) { build(:offender) }

  context 'when the offender exists in NOMIS' do
    before do
      stub_offender(build(:nomis_offender, prisonerNumber: offender.nomis_offender_id, prisonId: prison.code))
      expect(EarlyAllocationEventService).to receive(:send_early_allocation)
    end

    it 'sends the event via the job' do
      described_class.perform_now offender.nomis_offender_id
    end
  end

  context 'when that offender ID no longer exists in NOMIS' do
    before do
      stub_non_existent_offender(offender.nomis_offender_id)
      expect(EarlyAllocationEventService).not_to receive(:send_early_allocation)
    end

    it 'does not send the event' do
      described_class.perform_now offender.nomis_offender_id
    end
  end
end
