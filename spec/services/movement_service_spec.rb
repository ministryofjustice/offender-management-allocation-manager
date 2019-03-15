require 'rails_helper'
require_relative '../../app/services/nomis/models/movement'

describe MovementService, vcr: { cassette_name: :movement_service_spec } do
  let(:new_offender) {
    Nomis::Models::Movement.new.tap { |m|
      m.offender_no = 'G4273GI'
      m.to_agency = 'SWI'
      m.direction_code = 'IN'
      m.movement_type = 'ADM'
    }
  }
  let(:transfer_adm) {
    Nomis::Models::Movement.new.tap { |m|
      m.offender_no = 'G4273GI'
      m.from_agency = 'LEI'
      m.to_agency = 'SWI'
      m.direction_code = 'IN'
      m.movement_type = 'ADM'
    }
  }
  let(:transfer_out) {
    Nomis::Models::Movement.new.tap { |m|
      m.offender_no = 'G4273GI'
      m.from_agency = 'LEI'
      m.to_agency = 'SWI'
      m.direction_code = 'OUT'
      m.movement_type = 'TRN'
    }
  }
  let(:release) {
    Nomis::Models::Movement.new.tap { |m|
      m.offender_no = 'G4273GI'
      m.from_agency = 'LEI'
      m.direction_code = 'OUT'
      m.movement_type = 'REL'
    }
  }

  it "can get recent movements" do
    movements = MovementService.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
  end

  it "can filter transfer type results" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Models::MovementType::TRANSFER]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(0)
  end

  it "can filter admissions" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-03-12'),
      type_filters: [Nomis::Models::MovementType::ADMISSION]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Models::MovementType::ADMISSION)
  end

  it "can filter release type results" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Models::MovementType::RELEASE]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.movement_type).to eq(Nomis::Models::MovementType::RELEASE)
  end

  it "can filter results by direction IN" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-03-12'),
      direction_filters: [Nomis::Models::MovementDirection::IN]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Models::MovementDirection::IN)
  end

  it "can filter results by direction OUT" do
    movements = MovementService.movements_on(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::Models::MovementDirection::OUT]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Models::MovementDirection::OUT)
  end

  it "can process transfer movements IN" do
    processed = MovementService.process_movement(transfer_adm)
    expect(processed).to be true
  end

  it "can process release movements" do
    processed = MovementService.process_movement(release)
    expect(processed).to be true
  end

  it "can ignore movements OUT" do
    processed = MovementService.process_movement(transfer_out)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison" do
    processed = MovementService.process_movement(new_offender)
    expect(processed).to be false
  end
end
