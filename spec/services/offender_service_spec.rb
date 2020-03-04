require 'rails_helper'

describe OffenderService do
  let(:tier_map) { CaseInformationService.get_case_information('LEI') }

  it "gets a single offender", vcr: { cassette_name: :offender_service_single_offender_spec } do
    nomis_offender_id = 'G4273GI'

    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'C', case_allocation: 'CRC', welsh_offender: 'Yes')
    offender = described_class.get_offender(nomis_offender_id)

    expect(offender).to be_kind_of(Nomis::Offender)
    expect(offender.tier).to eq 'C'
    expect(offender.sentence.conditional_release_date).to eq(Date.new(2020, 3, 16))
    expect(offender.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    expect(offender.case_allocation).to eq 'CRC'
  end

  it "returns nil if offender record not found", vcr: { cassette_name: :offender_service_single_offender_not_found_spec } do
    nomis_offender_id = 'AAA121212CV4G4GGVV'

    offender = described_class.get_offender(nomis_offender_id)
    expect(offender).to be_nil
  end

  describe "#set_allocated_pom_name" do
    let(:offenders) { Prison.new('LEI').offenders.first(3) }
    let(:nomis_staff_id) { 485_926 }

    before do
      PomDetail.create!(nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')
    end

    it "gets the POM names for allocated offenders",
       vcr: { cassette_name: :offender_service_pom_names_spec } do
      allocate_offender(DateTime.now.utc)

      updated_offenders = described_class.set_allocated_pom_name(offenders, 'LEI')
      expect(updated_offenders).to be_kind_of(Array)
      expect(updated_offenders.first).to be_kind_of(Nomis::OffenderSummary)
      expect(updated_offenders.count).to eq(offenders.count)
      expect(updated_offenders.first.allocated_pom_name).to eq('Pom, Moic')
      expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
    end

    it "uses 'updated_at' date when 'primary_pom_allocated_at' date is nil",
       vcr: { cassette_name: :offender_service_set_allocated_pom_when_primary_pom_date_nil } do
      allocate_offender(nil)

      updated_offenders = described_class.set_allocated_pom_name(offenders, 'LEI')
      expect(updated_offenders.first.allocated_pom_name).to eq('Pom, Moic')
      expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
    end
  end

  def allocate_offender(allocated_date)
    Allocation.create!(
      nomis_offender_id: offenders.first.offender_no,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'C',
      created_by_username: 'MOIC_POM',
      primary_pom_nomis_id: nomis_staff_id,
      primary_pom_allocated_at: allocated_date,
      recommended_pom_type: 'prison',
      event: Allocation::ALLOCATE_PRIMARY_POM,
      event_trigger: Allocation::USER
    )
  end
end
