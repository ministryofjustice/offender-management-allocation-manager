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

  it "Can get the active allocations" do
    alloc = described_class.active_allocations([allocation.nomis_offender_id])
    expect(alloc).to be_instance_of(Hash)
  end

  it "can deallocate for a POM" do
    staff_id = allocation.nomis_staff_id
    described_class.deallocate_pom(staff_id)
    alloc = PrisonOffenderManagerService.get_allocations_for_pom(staff_id)
    expect(alloc).to eq([])
  end

  it "can deallocate for an offender" do
    offender_id = allocation.nomis_offender_id
    described_class.deallocate_offender(offender_id)
    alloc = described_class.active_allocations([offender_id])
    expect(alloc).to eq({})
  end
end
