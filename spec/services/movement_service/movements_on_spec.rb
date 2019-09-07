require 'rails_helper'

describe MovementService::MovementsOn do
  it "can get recent movements",
     vcr: { cassette_name: :movement_service_recent_spec }  do
    movements = described_class.call(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
  end

  it "can filter transfer type results",
     vcr: { cassette_name: :movement_service_filter_type_spec }  do
    movements = described_class.call(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Models::MovementType::TRANSFER]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(0)
  end

  it "can filter admissions",
     vcr: { cassette_name: :movement_service_filter_adm_spec }  do
    movements = described_class.call(
      Date.iso8601('2019-03-12'),
      type_filters: [Nomis::Models::MovementType::ADMISSION]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Models::MovementType::ADMISSION)
  end

  it "can filter release type results",
     vcr: { cassette_name: :movement_service_filter_release_spec }  do
    movements = described_class.call(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Models::MovementType::RELEASE]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Models::MovementType::RELEASE)
  end

  it "can filter results by direction IN",
     vcr: { cassette_name: :movement_service_filter_direction_in_spec }  do
    movements = described_class.call(
      Date.iso8601('2019-03-12'),
      direction_filters: [Nomis::Models::MovementDirection::IN]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Models::MovementDirection::IN)
  end

  it "can filter results by direction OUT",
     vcr: { cassette_name: :movement_service_filter_direction_out_spec }  do
    movements = described_class.call(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::Models::MovementDirection::OUT]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Models::MovementDirection::OUT)
  end
end
