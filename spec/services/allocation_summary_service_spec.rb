require 'rails_helper'

describe AllocationSummaryService do
  # TODO - Get feedback on test case
  it "will generate a summary", vcr: { cassette_name: :allocation_summary_service_summary } do
    summary = described_class.new.summary(1, 48, 15, 'LEI')

    expect(summary.allocated_page_count).to eq(0)
    expect(summary.unallocated_page_count).to eq(0)
    expect(summary.missing_page_count).to eq(63)
  end
end
