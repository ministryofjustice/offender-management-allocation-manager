require 'rails_helper'

describe SummaryService do
  # TODO: - Populate test db with Case Information
  it "will generate a summary", vcr: { cassette_name: :allocation_summary_service_summary } do
    summary = described_class.new.summary(:pending, 'LEI', 15)

    expect(summary.offenders.count).to eq(10)
    expect(summary.page_count).to eq(63)
  end
end
