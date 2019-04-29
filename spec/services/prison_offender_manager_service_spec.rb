require 'rails_helper'

describe PrisonOffenderManagerService do
  let(:staff_id) { 485_737 }

  let(:allocation_one) {
    AllocationService.create_allocation(
      primary_pom_nomis_id: staff_id,
      nomis_offender_id: 'G4273GI',
      created_by_username: 'RJONES',
      nomis_booking_id: 1_153_753,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  let(:allocation_two) {
    AllocationService.create_allocation(
      primary_pom_nomis_id: staff_id,
      nomis_offender_id: 'G8060UF',
      created_by_username: 'RJONES',
      nomis_booking_id: 971_856,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  let(:allocation_three) {
    AllocationService.create_allocation(
      primary_pom_nomis_id: staff_id,
      nomis_offender_id: 'G8624GK',
      created_by_username: 'RJONES',
      nomis_booking_id: 76_908,
      allocated_at_tier: 'B',
      prison: 'LEI'
    )
  }

  let(:allocation_four) {
    AllocationService.create_allocation(
      primary_pom_nomis_id: staff_id,
      nomis_offender_id: 'G1714GU',
      created_by_username: 'RJONES',
      nomis_booking_id: 31_777,
      allocated_at_tier: 'C',
      prison: 'LEI'
    )
  }

  let(:all_allocations) {
    [allocation_one, allocation_two, allocation_three, allocation_four]
  }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  it "can get staff names",
    vcr: { cassette_name: :pom_service_staff_name } do
    fname, lname = described_class.get_pom_name(staff_id)
    expect(fname).to eq('JAY')
    expect(lname).to eq('HEAL')
  end

  it "can get user names",
    vcr: { cassette_name: :pom_service_user_name } do
    fname, lname = described_class.get_user_name('RJONES')
    expect(fname).to eq('ROSS')
    expect(lname).to eq('JONES')
  end

  it "can get allocated offenders for a POM",
    vcr: { cassette_name: :pom_service_allocated_offenders } do
    allocated_offenders = described_class.get_allocated_offenders(allocation_one.primary_pom_nomis_id, 'LEI')

    alloc, sentence_detail = allocated_offenders.first
    expect(alloc).to be_kind_of(Allocation)
    expect(sentence_detail).to be_kind_of(Nomis::Models::SentenceDetail)
  end

  it "can get a subset of allocated offenders for a POM",
    vcr: { cassette_name: :pom_service_allocated_offenders_subset } do

    expected_total = all_allocations.size

    allocated_offenders = described_class.get_allocated_offenders(allocation_one.primary_pom_nomis_id, 'LEI')
    expect(allocated_offenders.count).to eq(expected_total)

    allocated_offenders = described_class.get_allocated_offenders(
      allocation_one.primary_pom_nomis_id, 'LEI',
      offset: 2, limit: 2)
    expect(allocated_offenders.count).to eq(2)
  end

  it "will get allocations for a POM made within the last 7 days", vcr: { cassette_name: :get_new_cases } do
    allocation_one.created_at = 10.days.ago
    allocation_one.save!
    allocation_two.created_at = 3.days.ago
    allocation_two.save!

    allocated_offenders = described_class.get_new_cases(allocation_one.primary_pom_nomis_id, 'LEI')
    expect(allocated_offenders.count).to eq 1
  end

  it "can get a list of POMs",
    vcr: { cassette_name: :pom_service_get_poms_list } do
    poms = described_class.get_poms('LEI')
    expect(poms).to be_kind_of(Array)
    expect(poms.count).to eq(13)
  end

  it "can get a filtered list of POMs",
    vcr: { cassette_name: :pom_service_get_poms_filtered } do
    poms = described_class.get_poms('LEI') { |pom|
      pom.status == 'active'
    }
    expect(poms).to be_kind_of(Array)
    expect(poms.count).to eq(12)
  end

  it "can get the names for POMs when given IDs",
    vcr: { cassette_name: :pom_service_get_poms_by_ids } do
    names = described_class.get_pom_names('LEI')
    expect(names).to be_kind_of(Hash)
    expect(names.count).to eq(12)
  end

  it "can fetch a single POM for a prison",
    vcr: { cassette_name: :pom_service_get_pom_ok } do
    pom = described_class.get_pom('LEI', staff_id)
    expect(pom).not_to be nil
  end

  it "can handle no poms for a prison when fetching a pom",
    vcr: { cassette_name: :pom_service_get_pom_none } do
    pom = described_class.get_pom('CFI', 1234)
    expect(pom).to be nil
  end

  it "can handle a pom not existing at a prison",
    vcr: { cassette_name: :pom_service_get_pom_fail } do
    pom = described_class.get_pom('LEI', 1234)
    expect(pom).to be nil
  end
end
