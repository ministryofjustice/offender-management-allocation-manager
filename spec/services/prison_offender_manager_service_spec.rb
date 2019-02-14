require 'rails_helper'
require_relative '../../app/services/nomis/elite2/sentence_detail'

describe PrisonOffenderManagerService do
  let(:pom_detail) {
    described_class.get_pom_detail(485_595)
  }
  let(:allocation) {
    AllocationService.create_allocation(
      nomis_staff_id: pom_detail.nomis_staff_id,
      nomis_offender_id: 'G2911GD',
      created_by: 'Test User',
      nomis_booking_id: 0,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  it "can get allocated offenders for a POM",
    vcr: { cassette_name: :pom_service_allocated_offenders } do
    allocated_offenders = described_class.get_allocated_offenders(allocation.nomis_staff_id)

    alloc, sentence_detail = allocated_offenders.first
    expect(alloc).to be_kind_of(Allocation)
    expect(sentence_detail).to be_kind_of(Nomis::Elite2::SentenceDetail)
  end

  it "can get a list of POMs",
    vcr: { cassette_name: :pom_service_get_poms } do
    poms = described_class.get_poms('LEI')
    expect(poms).to be_kind_of(Array)
    expect(poms.count).to eq(5)
  end

  it "can get the names for POMs when given IDs",
    vcr: { cassette_name: :pom_service_get_poms } do
    names = described_class.get_pom_names('LEI')
    expect(names).to be_kind_of(Hash)
    expect(names.count).to eq(5)
  end
end
