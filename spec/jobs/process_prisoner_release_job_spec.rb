# frozen_string_literal: true

RSpec.describe ProcessPrisonerReleaseJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:last_movement) { double('Movement') }

  before do
    allow(HmppsApi::PrisonApi::MovementApi).to receive(:movements_for)
                                                 .with(nomis_offender_id, movement_types: [])
                                                 .and_return(double(last_movement:))
    allow(MovementService).to receive(:process_movement)
  end

  it 'processes the last movement' do
    expect(MovementService).to receive(:process_movement).with(last_movement)
    described_class.perform_now(nomis_offender_id)
  end

  context 'when there is no last movement' do
    before do
      allow(HmppsApi::PrisonApi::MovementApi).to receive(:movements_for).and_return(double(last_movement: nil))
    end

    it 'does not call MovementService.process_movement' do
      expect(MovementService).not_to receive(:process_movement)
      described_class.perform_now(nomis_offender_id)
    end
  end
end
