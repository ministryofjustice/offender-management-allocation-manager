require 'rails_helper'

RSpec.describe SummaryHelper do
  describe 'start_date' do
    let(:prison_dates) do
      [
          { offender_no: "A1120GH", days_count: 199 },
          { offender_no: "G9765JZ", days_count: 50 }
      ]
    end

    it "formats an offender's prison start date if offender exists" do
      expect(start_date(prison_dates, "A1120GH")).to eq(199)
    end

    it "formats an offender's prison start date if offender does not exist" do
      expect(start_date(prison_dates, "Z1234WQ")).to eq('-')
    end
  end
end
