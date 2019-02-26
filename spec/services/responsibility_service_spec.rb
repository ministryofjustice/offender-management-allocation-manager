require 'rails_helper'

describe ResponsibilityService do
  let(:offender_none){
    Nomis::Models::Offender.new
  }
  let(:offender_crc){
    Nomis::Models::Offender.new.tap { |o| o.case_allocation = 'CRC' }
  }
  let(:offender_nps_gt_10){
    Nomis::Models::Offender.new.tap { |o|
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 12.months
    }
  }
  let(:offender_nps_lt_10){
    Nomis::Models::Offender.new.tap { |o|
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 6.months
    }
  }
  let(:offender_nps_no_release_date){
    Nomis::Models::Offender.new.tap { |o| o.case_allocation = 'NPS' }
  }

  it "CRC allocations means Prison" do
    resp = described_class.calculate_responsibility(offender_crc)
    expect(resp).to eq 'Prison'
  end

  it "NPS allocations with no release date" do
    resp = described_class.calculate_responsibility(offender_nps_no_release_date)
    expect(resp).to eq 'No release date'
  end

  it "No allocation" do
    resp = described_class.calculate_responsibility(offender_none)
    expect(resp).to eq 'Unknown'
  end
end
