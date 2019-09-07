require 'rails_helper'

describe SearchService::Search do
  it "will return all of the records if no search", vcr: { cassette_name: :search_service_all } do
    offenders = described_class.call('', 'LEI')
    expect(offenders.count).to eq(823)
  end

  it "will return a filtered list if there is a search", vcr: { cassette_name: :search_service_filtered } do
    offenders = described_class.call('Cal', 'LEI')
    expect(offenders.count).to eq(6)
  end

  it "will handle a nil search term", vcr: { cassette_name: :search_service_no_term } do
    offenders = described_class.call(nil, 'LEI')
    expect(offenders.count).to eq(0)
  end
end
