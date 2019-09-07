require 'rails_helper'

describe OffenderService::Get do
  it "gets a single offender", vcr: { cassette_name: :offender_service_single_offender_spec } do
    nomis_offender_id = 'G4273GI'

    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'C', case_allocation: 'CRC', omicable: 'Yes')

    offender = described_class.call(nomis_offender_id)

    expect(offender).to be_kind_of(Nomis::Models::Offender)
    expect(offender.sentence.release_date).to eq Date.new(2020, 2, 7)
    expect(offender.tier).to eq 'C'
    expect(offender.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    expect(offender.case_allocation).to eq 'CRC'
  end

  it "returns nil if offender record not found", vcr: { cassette_name: :offender_service_single_offender_not_found_spec } do
    nomis_offender_id = 'AAA121212CV4G4GGVV'

    offender = described_class.call(nomis_offender_id)
    expect(offender).to be_nil
  end
end
