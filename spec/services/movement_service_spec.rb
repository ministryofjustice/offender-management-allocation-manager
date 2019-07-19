require 'rails_helper'
require_relative '../../app/services/nomis/models/movement'

describe MovementService do
  let(:new_offender) {
    Nomis::Models::Movement.new.tap { |m|
      m.offender_no = 'G4273GI'
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

  it "can get recent movements",
     vcr: { cassette_name: :movement_service_recent_spec }  do
    movements = described_class.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
  end

  it "can filter transfer type results",
     vcr: { cassette_name: :movement_service_filter_type_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::Models::MovementType::TRANSFER]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(0)
  end

  it "can filter admissions",
     vcr: { cassette_name: :movement_service_filter_adm_spec }  do
    movements = described_class.movements_on(
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
    movements = described_class.movements_on(
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
    movements = described_class.movements_on(
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
    movements = described_class.movements_on(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::Models::MovementDirection::OUT]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    expect(movements.first.direction_code).to eq(Nomis::Models::MovementDirection::OUT)
  end

  it "can ignore movements OUT",
     vcr: { cassette_name: :movement_service_ignore_out_spec }  do
    processed = described_class.process_movement(transfer_out)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison",
     vcr: { cassette_name: :movement_service_ignore_new_spec }  do
    processed = described_class.process_movement(new_offender)
    expect(processed).to be false
  end

  describe "processing an offender transfer" do
    let!(:allocation) {
      # The original allocation before the transfer
      AllocationVersion.find_or_create_by!(
        primary_pom_nomis_id: 485_737,
        nomis_offender_id: 'G4273GI',
        created_by_username: 'PK000223',
        nomis_booking_id: 0,
        allocated_at_tier: 'A',
        prison: 'LEI',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      )
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

    it "can process transfer movements IN",
       vcr: { cassette_name: :movement_service_transfer_in_spec }  do
      processed = described_class.process_movement(transfer_adm)
      updated_allocation = AllocationVersion.find_by(nomis_offender_id: transfer_adm.offender_no)

      expect(updated_allocation.primary_pom_name).to be_nil
      expect(updated_allocation.event).to eq 'deallocate_primary_pom'
      expect(updated_allocation.event_trigger).to eq 'offender_transferred'
      expect(processed).to be true
    end
  end

  describe "processing an offender release" do
    let!(:release) {
      Nomis::Models::Movement.new.tap { |m|
        m.offender_no = 'G4273GI'
        m.from_agency = 'LEI'
        m.direction_code = 'OUT'
        m.movement_type = 'REL'
      }
    }
    let!(:caseinfo) {
      CaseInformation.find_or_create_by!(
        nomis_offender_id: 'G4273GI',
        tier: 'A',
        case_allocation: 'NPS',
        omicable: 'Yes'
      )
    }
    let!(:allocation) {
      # The original allocation before the release
      AllocationVersion.find_or_create_by!(
        primary_pom_nomis_id: 485_737,
        nomis_offender_id: 'G4273GI',
        created_by_username: 'PK000223',
        nomis_booking_id: 0,
        allocated_at_tier: 'A',
        prison: 'LEI',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      )
    }

    it "can process release movements", vcr: { cassette_name: :movement_service_process_release_spec }  do
      processed = described_class.process_movement(release)
      updated_allocation = AllocationVersion.find_by(nomis_offender_id: release.offender_no)

      expect(CaseInformationService.get_case_information([release.offender_no])).to be_empty
      expect(updated_allocation.event_trigger).to eq 'offender_released'
      expect(updated_allocation.prison).to be_nil
      expect(processed).to be true
    end
  end
end
