RSpec.describe MovementsOnDateJob, type: :job do
  it 'invokes MovementJob#perform_later for every movement from yesterday' do
    today_str = '2020-06-12'
    yesterday = Date.new(2020, 6, 11)
    movements = [double(:movement1), double(:movement2)]
    allow(MovementJob).to receive(:perform_later)

    allow(MovementService).to receive(:movements_on)
    allow(MovementService).to receive(:movements_on).with(yesterday).and_return(movements)

    described_class.perform_now(today_str)

    aggregate_failures do
      expect(MovementJob).to have_received(:perform_later).with(movements[0].to_json)
      expect(MovementJob).to have_received(:perform_later).with(movements[1].to_json)
    end
  end
end
