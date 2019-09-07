require 'rails_helper'

describe OffenderService::List do
  it "get first page of offenders for a specific prison",
     vcr: { cassette_name: :offender_service_offenders_by_prison_first_page_spec } do
    offenders = described_class.call('LEI').first(9)
    expect(offenders).to be_kind_of(Array)
    expect(offenders.length).to eq(9)
    expect(offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
  end

  it "get last page of offenders for a specific prison", vcr: { cassette_name: :offender_service_offenders_by_prison_last_page_spec } do
    offenders = described_class.call('LEI').to_a
    expect(offenders).to be_kind_of(Array)
    expect(offenders.length).to eq(823)
    expect(offenders.first).to be_kind_of(Nomis::Models::OffenderSummary)
  end
end
