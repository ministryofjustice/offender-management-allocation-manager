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
end
