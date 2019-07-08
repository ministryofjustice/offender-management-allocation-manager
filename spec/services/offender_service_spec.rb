require 'rails_helper'

describe OffenderService do
  it "get first page of offenders for a specific prison",
     vcr: { cassette_name: :offender_service_offenders_by_prison_first_page_spec } do
    offenders = described_class.get_offenders_for_prison('LEI', page_number: 0, page_size: 10)
    expect(offenders).to be_kind_of(Array)
    expect(offenders.length).to eq(9)
    expect(offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
  end

  it "get last page of offenders for a specific prison", vcr: { cassette_name: :offender_service_offenders_by_prison_last_page_spec } do
    offenders = described_class.get_offenders_for_prison('LEI', page_number: 93, page_size: 10)
    expect(offenders).to be_kind_of(Array)
    expect(offenders.length).to eq(1)
    expect(offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
  end

  it "gets a single offender", vcr: { cassette_name: :offender_service_single_offender_spec } do
    nomis_offender_id = 'G4273GI'

    CaseInformation.create(nomis_offender_id: nomis_offender_id, tier: 'C', case_allocation: 'CRC', omicable: 'Yes')
    offender = described_class.get_offender(nomis_offender_id)

    expect(offender).to be_kind_of(Nomis::Models::Offender)
    expect(offender.sentence.release_date).to eq Date.new(2020, 2, 7)
    expect(offender.tier).to eq 'C'
    expect(offender.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    expect(offender.case_allocation).to eq 'CRC'
  end

  it "gets the POM names for allocated offenders",
     vcr: { cassette_name: :offender_service_pom_names_spec } do
    offenders = described_class.get_offenders_for_prison('LEI', page_size: 3, page_number: 0)
    nomis_staff_id = 485_752

    PomDetail.create!(nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')

    AllocationVersion.create!(
      nomis_offender_id: offenders.first.offender_no,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'C',
      created_by_username: 'PK000223',
      primary_pom_nomis_id: nomis_staff_id,
      primary_pom_allocated_at: DateTime.now.utc,
      recommended_pom_type: 'prison',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )

    updated_offenders = described_class.set_allocated_pom_name(offenders, 'LEI')
    expect(updated_offenders).to be_kind_of(Array)
    expect(updated_offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
    expect(updated_offenders.count).to eq(offenders.count)
    expect(updated_offenders.first.allocated_pom_name).to eq('Jones, Ross')
    expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
  end
end
