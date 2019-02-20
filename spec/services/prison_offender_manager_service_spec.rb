require 'rails_helper'
require_relative '../../app/services/nomis/elite2/sentence_detail'
require_relative '../../app/services/nomis/elite2/offender'

describe PrisonOffenderManagerService do
  let(:staff_id) { 485_737 }

  let(:allocation_one) {
    AllocationService.create_allocation(
      nomis_staff_id: staff_id,
      nomis_offender_id: 'G2911GD',
      created_by: 'Test User',
      nomis_booking_id: 0,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  let(:allocation_two) {
    AllocationService.create_allocation(
      nomis_staff_id: staff_id,
      nomis_offender_id: 'G8060UF',
      created_by: 'Test User',
      nomis_booking_id: 1,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  it "can get allocated offenders for a POM",
    vcr: { cassette_name: :pom_service_allocated_offenders } do
    allocated_offenders = described_class.get_allocated_offenders(allocation_one.nomis_staff_id)

    alloc, sentence_detail = allocated_offenders.first
    expect(alloc).to be_kind_of(Allocation)
    expect(sentence_detail).to be_kind_of(Nomis::Elite2::SentenceDetail)
  end

  it "will get allocations for a POM made within the last 7 days", vcr: { cassette_name: :get_new_cases } do
    allocation_one.created_at = 10.days.ago
    allocation_one.save!
    allocation_two.created_at = 3.days.ago
    allocation_two.save!

    allocated_offenders = described_class.get_new_cases(allocation_one.nomis_staff_id)
    expect(allocated_offenders.count).to eq 1
  end

  it "can get a list of POMs",
    vcr: { cassette_name: :pom_service_get_poms } do
    poms = described_class.get_poms('LEI')
    expect(poms).to be_kind_of(Array)
    expect(poms.count).to eq(9)
  end

  it "can get a filtered list of POMs",
    vcr: { cassette_name: :pom_service_get_poms } do
    poms = described_class.get_poms('LEI') { |pom|
      pom.status == 'active'
    }
    expect(poms).to be_kind_of(Array)
    expect(poms.count).to eq(8)
  end

  it "can get the names for POMs when given IDs",
    vcr: { cassette_name: :pom_service_get_poms } do
    names = described_class.get_pom_names('LEI')
    expect(names).to be_kind_of(Hash)
    expect(names.count).to eq(8)
  end
end
