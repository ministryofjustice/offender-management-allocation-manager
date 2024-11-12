require 'rails_helper'

describe SearchService do
  let(:offenders) { OffenderService.get_offenders_in_prison(Prison.new(code: 'LEI')) }
  let(:oakwood_offenders) { OffenderService.get_offenders_in_prison(Prison.new(code: 'OWI')) }

  it "will return all of the records if no search", vcr: { cassette_name: 'prison_api/search_service_all' } do
    expect(described_class.search_for_offenders('', offenders).count).to be > 800
  end

  it "will return a filtered list if there is a search", vcr: { cassette_name: 'prison_api/search_service_filtered' } do
    expect(described_class.search_for_offenders('Cal', offenders).count).to eq(5)
  end

  it "will handle a nil search term", vcr: { cassette_name: 'prison_api/search_service_no_term' } do
    expect(described_class.search_for_offenders(nil, offenders).count).to eq(0)
  end
end
