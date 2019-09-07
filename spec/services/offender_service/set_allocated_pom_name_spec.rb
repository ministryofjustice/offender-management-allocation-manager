require 'rails_helper'

describe OffenderService::SetAllocatedPomName do
  let(:offenders) { OffenderService::List.call('LEI').first(3) }
  let(:nomis_staff_id) { 485_752 }

  before do
    PomDetail.create!(nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')
  end

  it "gets the POM names for allocated offenders",
     vcr: { cassette_name: :offender_service_pom_names_spec } do
    allocate_offender(DateTime.now.utc)

    updated_offenders = described_class.call(offenders, 'LEI')
    expect(updated_offenders).to be_kind_of(Array)
    expect(updated_offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
    expect(updated_offenders.count).to eq(offenders.count)
    expect(updated_offenders.first.allocated_pom_name).to eq('Jones, Ross')
    expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
  end

  it "uses 'updated_at' date when 'primary_pom_allocated_at' date is nil",
     vcr: { cassette_name: :offender_service_set_allocated_pom_when_primary_pom_date_nil } do
    allocate_offender(nil)

    updated_offenders = described_class.call(offenders, 'LEI')
    expect(updated_offenders.first.allocated_pom_name).to eq('Jones, Ross')
    expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
  end

  def allocate_offender(allocated_date)
    AllocationVersion.create!(
      nomis_offender_id: offenders.first.offender_no,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'C',
      created_by_username: 'PK000223',
      primary_pom_nomis_id: nomis_staff_id,
      primary_pom_allocated_at: allocated_date,
      recommended_pom_type: 'prison',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )
  end
end
