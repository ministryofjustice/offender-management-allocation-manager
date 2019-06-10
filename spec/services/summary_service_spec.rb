require 'rails_helper'

describe SummaryService do
  # TODO: - Populate test db with Case Information
  it "will generate a summary", vcr: { cassette_name: :allocation_summary_service_summary } do
    summary = described_class.new.summary(:pending, 'LEI', 15, SummaryService::SummaryParams.new)

    expect(summary.offenders.count).to eq(10)
    expect(summary.page_count).to eq(82)
  end

  it "will sort a summary", vcr: { cassette_name: :allocation_summary_service_summary_sort } do
    asc_summary = described_class.new.summary(
      :pending,
      'LEI',
      1,
      SummaryService::SummaryParams.new(sort_field: :last_name)
    )
    asc_cells = asc_summary.offenders.map(&:offender_no)

    desc_summary = described_class.new.summary(
      :pending,
      'LEI',
      1,
      SummaryService::SummaryParams.new(sort_direction: :desc, sort_field: :last_name)
    )
    desc_cells = desc_summary.offenders.map(&:offender_no)

    expect(asc_cells).not_to match_array(desc_cells)
  end
end
