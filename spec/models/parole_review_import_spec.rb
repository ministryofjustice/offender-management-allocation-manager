require "rails_helper"

describe ParoleReviewImport do
  describe "Review date" do
    specify 'for single day snapshots the date comes in %d-%m-%Y format' do
      import = described_class.new(single_day_snapshot: true, review_date: '20-11-2024')
      expect(import.review_date).to eq(Date.parse('20/11/2024'))
    end

    specify 'for non single day snapshots the date comes in %m/%d/%y format' do
      import = described_class.new(single_day_snapshot: false, review_date: '3/28/18')
      expect(import.review_date).to eq(Date.parse('28/03/2018'))
    end
  end
end
