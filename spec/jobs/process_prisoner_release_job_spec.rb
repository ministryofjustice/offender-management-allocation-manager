# frozen_string_literal: true

RSpec.describe ProcessPrisonerReleaseJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }

  before do
    allow(MovementService).to receive(:process_offender_last_movement)
  end

  it 'delegates release handling to MovementService' do
    expect(MovementService).to receive(:process_offender_last_movement).with(nomis_offender_id)
    described_class.perform_now(nomis_offender_id)
  end

  context 'when movement processing does not find a releasable movement' do
    before do
      allow(MovementService).to receive(:process_offender_last_movement).and_return(false)
    end

    it 'still routes processing through MovementService without raising' do
      expect(MovementService).to receive(:process_offender_last_movement).with(nomis_offender_id)
      described_class.perform_now(nomis_offender_id)
    end
  end
end
