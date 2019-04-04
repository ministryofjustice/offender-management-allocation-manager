require 'rails_helper'

RSpec.describe AllocationService do
  let(:allocation) {
    described_class.create_allocation(
      nomis_staff_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by: 'Test User',
      nomis_booking_id: 0,
      allocated_at_tier: 'A',
      prison: 'LEI'
    )
  }

  let(:inactive_allocation) {
    described_class.create_allocation(
      nomis_staff_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by: 'Test User',
      nomis_booking_id: 0,
      allocated_at_tier: 'A',
      prison: 'LEI',
      active: false
    )
  }

  it "Can get the active allocations", vcr: { cassette_name: 'allocation_service_get_allocations' } do
    alloc = described_class.active_allocations([allocation.nomis_offender_id])
    expect(alloc).to be_instance_of(Hash)
  end

  it "Can tell if an allocated offender has an active allocation", vcr: { cassette_name: 'allocation_service_has_active_allocation' } do
    alloc = described_class.active_allocation?(allocation.nomis_offender_id)
    expect(alloc).to eq(true)
  end

  it "Can tell if an allocated offender has no active allocation", vcr: { cassette_name: 'allocation_service_has_no_active_allocation' } do
    alloc = described_class.active_allocation?('G1670VU')
    expect(alloc).to eq(false)
  end

  it "Can get previous allocations for an offender where there are none", vcr: { cassette_name: 'allocation_service_previous_allocations_none' } do
    staff_ids = described_class.previously_allocated_poms(allocation.nomis_offender_id)
    expect(staff_ids).to eq([])
  end

  it "Can get previous allocations for an offender where there are some", vcr: { cassette_name: 'allocation_service_previous_allocations' } do
    staff_ids = described_class.previously_allocated_poms(inactive_allocation.nomis_offender_id)
    expect(staff_ids.count).to eq(1)
    expect(staff_ids.first).to eq(485_595)
  end

  it "can deallocate for a POM", vcr: { cassette_name: 'allocation_service_deallocate_a_pom' } do
    staff_id = allocation.nomis_staff_id
    described_class.deallocate_pom(staff_id)
    alloc = PrisonOffenderManagerService.get_allocations_for_pom(staff_id, 'LEI')
    expect(alloc).to eq([])
  end

  it "can deallocate for an offender", vcr: { cassette_name: 'allocation_service_deallocate_an_offender' } do
    offender_id = allocation.nomis_offender_id
    described_class.deallocate_offender(offender_id)
    alloc = described_class.active_allocations([offender_id])
    expect(alloc).to eq({})
  end
end
