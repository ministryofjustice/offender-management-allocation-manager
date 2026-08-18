# frozen_string_literal: true

RSpec.describe MovementJob, type: :job do
  let(:first_movement) { build(:movement, offenderNo: 'A1234BC', movementTime: '08:00:00') }
  let(:second_movement) { build(:movement, offenderNo: 'A1234BC', movementTime: '12:00:00') }

  before do
    allow(MovementService).to receive(:process_movement)
  end

  it 'processes a single movement payload' do
    described_class.perform_now(first_movement.job_payload)

    expect(MovementService).to have_received(:process_movement).with(
      have_attributes(offender_no: 'A1234BC', movement_type: first_movement.movement_type)
    )
  end

  it 'processes an ordered sequence of movement payloads' do
    described_class.perform_now([first_movement.job_payload, second_movement.job_payload])

    expect(MovementService).to have_received(:process_movement).ordered.with(
      have_attributes(offender_no: 'A1234BC', happened_at: first_movement.happened_at)
    )
    expect(MovementService).to have_received(:process_movement).ordered.with(
      have_attributes(offender_no: 'A1234BC', happened_at: second_movement.happened_at)
    )
  end

  it 'rebuilds movement objects from explicit job payloads' do
    described_class.perform_now(first_movement.job_payload)

    expect(MovementService).to have_received(:process_movement).with(
      have_attributes(
        offender_no: first_movement.offender_no,
        from_agency: first_movement.from_agency,
        to_agency: first_movement.to_agency,
        movement_type: first_movement.movement_type,
        happened_at: first_movement.happened_at,
      )
    )
  end
end
