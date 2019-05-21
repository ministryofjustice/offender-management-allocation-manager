require 'rails_helper'

describe DateMigrater do
  it "migrates 'created_at' dates from Allocations to AllocationVersions" do
    nomis_offender_id = 'ABD1234'
    another_nomis_offender_id = 'ZZZ1234'
    created_at_date = DateTime.new(2019, 05, 03).utc
    primary_pom_allocated_at = DateTime.new(2019, 05, 19).utc

    create(
      :allocation,
      nomis_offender_id: nomis_offender_id,
      created_at: created_at_date,
      active: true
    )

    create(
      :allocation,
      nomis_offender_id: another_nomis_offender_id,
      created_at: created_at_date,
      active: false
    )

    create(
      :allocation,
      nomis_offender_id: 'No corresponding AllocationVersion',
      created_at: created_at_date,
      active: true
    )

    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id
    )

    create(
      :allocation_version,
      nomis_offender_id: another_nomis_offender_id,
      primary_pom_allocated_at: primary_pom_allocated_at
    )

    described_class.run

    changed_allocation_version = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)
    unchanged_allocation_version = AllocationVersion.find_by(nomis_offender_id: another_nomis_offender_id)

    # Only active Allocations should be migrated
    # Only Allocations with a corresponding AllocationVersion should be migrated

    expect(changed_allocation_version.primary_pom_allocated_at).to eq(created_at_date)
    expect(unchanged_allocation_version.primary_pom_allocated_at).to eq(primary_pom_allocated_at)
  end
end
