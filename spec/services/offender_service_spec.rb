require 'rails_helper'

describe OffenderService, vcr: { cassette_name: :offender_service_offenders_by_prison_spec } do
  it "get first page of offenders for a specific prison" do
    offenders = OffenderService.new.get_offenders_for_prison('LEI')
    expect(offenders.meta).to be_kind_of(PageMeta)
    expect(offenders.data).to be_kind_of(Array)
    expect(offenders.data.length).to eq(5)
    expect(offenders.data.first).to be_kind_of(Nomis::Elite2::OffenderShort)
  end

  it "get last page of offenders for a specific prison", vcr: { cassette_name: :offender_service_offenders_by_prison_last_page_spec } do
    offenders = OffenderService.new.get_offenders_for_prison('LEI', page_number: 116)
    expect(offenders.meta).to be_kind_of(PageMeta)
    expect(offenders.data).to be_kind_of(Array)
    expect(offenders.data.length).to eq(5)
    expect(offenders.data.first).to be_kind_of(Nomis::Elite2::OffenderShort)
  end

  it "gets a single offender", vcr: { cassette_name: :offender_service_single_offender_spec } do
    noms_id = 'G4273GI'
    offender = OffenderService.new.get_offender(noms_id)
    expect(offender.data).to be_kind_of(Nomis::Elite2::Offender)
    expect(offender.data.release_date).to eq Date.new(2020, 2, 7)
    expect(offender.data.tier).to eq 'C'
    expect(offender.data.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    expect(offender.data.case_allocation).to eq 'CRC'
  end
end
