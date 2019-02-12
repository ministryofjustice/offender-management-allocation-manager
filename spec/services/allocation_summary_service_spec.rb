require 'rails_helper'

describe AllocationSummaryService do
  it "will generate a summary", vcr: {cassette_name: :allocation_summary_service_summary} do
    summary = described_class.summary(1, 48, 15, 'LEI')

    expect(summary.unallocated_page_count).to eq(48)
    expect(summary.missing_page_count).to eq(15)
  end

end