require 'rails_helper'

describe OffenderService, vcr: { cassette_name: :get_offenders_for_specific_prison } do
  it "get first page of offenders for a specific prison" do
    offenders = OffenderService.new.get_offenders_for_prison('LEI')
    expect(offenders.meta).to be_kind_of(PageMeta)
    expect(offenders.data).to be_kind_of(Array)
    expect(offenders.data.length).to eq(10)
    expect(offenders.data.first).to be_kind_of(Nomis::OffenderShort)
  end

  it "get last page of offenders for a specific prison", vcr: { cassette_name: :get_offenders_for_specific_prison_last_page } do
    offenders = OffenderService.new.get_offenders_for_prison('LEI', page_number: 116)
    expect(offenders.meta).to be_kind_of(PageMeta)
    expect(offenders.data).to be_kind_of(Array)
    expect(offenders.data.length).to eq(7)
    expect(offenders.data.first).to be_kind_of(Nomis::OffenderShort)
  end

  it "gets a single offender", vcr: { cassette_name: :get_single_offender } do
    noms_id = 'G4273GI'
    offender = OffenderService.new.get_offender(noms_id)
    expect(offender.data).to be_kind_of(Nomis::Offender)
  end
end
