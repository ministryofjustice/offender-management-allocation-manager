require 'rails_helper'

RSpec.describe AllocationList, type: :model do
  let(:current_allocation) {
    AllocationService.create_allocation(
      nomis_staff_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 1,
      allocated_at_tier: 'A',
      prison: 'LEI',
      created_at: '01/01/2019'
    )
  }

  let(:middle_allocation1) {
    AllocationService.create_allocation(
      nomis_staff_id: 485_752,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 2,
      allocated_at_tier: 'A',
      prison: 'PVI',
      active: false,
      created_at: '01/01/2018'
    )
  }

  let(:middle_allocation2) {
    AllocationService.create_allocation(
      nomis_staff_id: 485_752,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 3,
      allocated_at_tier: 'A',
      prison: 'PVI',
      active: false,
      created_at: '01/01/2017'
    )
  }

  let(:old_allocation) {
    AllocationService.create_allocation(
      nomis_staff_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 4,
      allocated_at_tier: 'A',
      prison: 'LEI',
      active: false,
      created_at: '01/01/2016'
    )
  }

  it 'can group the allocations correctly', vcr: { cassette_name: :allocation_list_spec } do
    list = AllocationList.new([current_allocation, middle_allocation1, middle_allocation2, old_allocation])
    expect(list.count).to eq(4)

    results = []

    list.grouped_by_prison do |prison, allocations|
      results << [prison, allocations]
    end

    prison, allocations = results.shift
    expect(prison).to eq('LEI')
    expect(allocations.count).to eq(1)

    prison, allocations = results.shift
    expect(prison).to eq('PVI')
    expect(allocations.count).to eq(2)

    prison, allocations = results.shift
    expect(prison).to eq('LEI')
    expect(allocations.count).to eq(1)
  end
end
