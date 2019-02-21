require 'rails_helper'

describe MovementService, vcr: { cassette_name: :movement_service_spec } do
  it "can get recent movements" do
    movements = MovementService.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(3)
    expect(movements.first).to be_kind_of(Nomis::Elite2::Movement)
  end

  it "can filter transfer type results" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Elite2::MovementType::TRANSFER]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(0)
  end

  it "can filter admissions" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Elite2::MovementType::ADMISSION]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Elite2::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Elite2::MovementType::ADMISSION)
  end

  it "can filter release type results" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Elite2::MovementType::RELEASE]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Elite2::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Elite2::MovementType::RELEASE)
  end

  it "can filter results by direction IN" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::Elite2::MovementDirection::IN]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Elite2::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Elite2::MovementDirection::IN)
  end

  it "can filter results by direction OUT" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::Elite2::MovementDirection::OUT]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Elite2::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Elite2::MovementDirection::OUT)
  end
end
