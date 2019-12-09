require 'rails_helper'

describe SummaryService do
  it "will sort a summary", vcr: { cassette_name: :allocation_summary_service_summary_sort } do
    asc_summary = described_class.summary(
      :pending,
      Prison.new('LEI'),
      SummaryService::SummaryParams.new(sort_field: :last_name)
    )
    asc_cells = asc_summary.offenders.map(&:offender_no)

    desc_summary = described_class.summary(
      :pending,
      Prison.new('LEI'),
      SummaryService::SummaryParams.new(sort_direction: :desc, sort_field: :last_name)
    )
    desc_cells = desc_summary.offenders.map(&:offender_no)

    expect(asc_cells).not_to eq(desc_cells)
  end
end
