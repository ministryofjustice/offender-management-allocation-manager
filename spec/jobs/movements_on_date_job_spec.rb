RSpec.describe MovementsOnDateJob, type: :job do
  let(:target_date) { Date.parse('2020-06-11') }
  let(:target_date_str) { target_date.to_s }

  it 'invokes MovementJob once per offender with ordered job payloads and cache disabled' do
    earlier_movement = build(:movement, offenderNo: 'A1234BC', movementDate: target_date_str, movementTime: '08:00:00')
    later_movement = build(:movement, offenderNo: 'A1234BC', movementDate: target_date_str, movementTime: '12:00:00')
    other_offender_movement = build(:movement, offenderNo: 'B1234CD', movementDate: target_date_str, movementTime: '09:00:00')
    movements = [later_movement, other_offender_movement, earlier_movement]

    allow(MovementJob).to receive(:perform_later)
    allow(MovementService).to receive(:movements_on)
      .with(target_date, cache: false)
      .and_return(movements)

    described_class.perform_now(target_date_str)

    aggregate_failures do
      expect(MovementJob).to have_received(:perform_later).with([
        earlier_movement.job_payload,
        later_movement.job_payload,
      ])
      expect(MovementJob).to have_received(:perform_later).with([
        other_offender_movement.job_payload,
      ])
    end
  end

  it 'does not enqueue movement jobs when no movements are returned' do
    allow(MovementJob).to receive(:perform_later)
    allow(MovementService).to receive(:movements_on)
      .with(target_date, cache: false)
      .and_return([])

    described_class.perform_now(target_date_str)

    expect(MovementJob).not_to have_received(:perform_later)
  end
end
