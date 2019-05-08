require 'rails_helper'

RSpec.describe AllocationList, type: :model do
  let(:current_allocation) {
    AllocationVersion.create!(
      primary_pom_nomis_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 1,
      allocated_at_tier: 'A',
      prison: 'LEI',
      created_at: '01/01/2019',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )
  }

  let(:middle_allocation1) {
    AllocationVersion.create!(
      primary_pom_nomis_id: 485_752,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 2,
      allocated_at_tier: 'A',
      prison: 'PVI',
      created_at: '01/01/2018',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )
  }

  let(:middle_allocation2) {
    AllocationVersion.create!(
      primary_pom_nomis_id: 485_752,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 3,
      allocated_at_tier: 'A',
      prison: 'PVI',
      created_at: '01/01/2017',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )
  }

  let(:old_allocation) {
    AllocationVersion.create!(
      primary_pom_nomis_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 4,
      allocated_at_tier: 'A',
      prison: 'LEI',
      created_at: '01/01/2016',
      event: AllocationVersion::REALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
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
