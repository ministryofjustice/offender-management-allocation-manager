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
  let(:offender_welsh_gt_10){
    Nomis::Models::Offender.new.tap { |o|
      o.release_date = DateTime.now.utc.to_date + 12.months
      o.welsh_address = true
    }
  }
  let(:offender_welsh_lt_10){
    Nomis::Models::Offender.new.tap { |o|
      o.release_date = DateTime.now.utc.to_date + 6.months
      o.welsh_address = false
    }
  }
  let(:offender_nps_no_release_date){
    Nomis::Models::Offender.new.tap { |o| o.case_allocation = 'NPS' }
  }

  describe 'case owner' do
    it "CRC allocations means Prison" do
      resp = described_class.calculate_case_owner(offender_crc)
      expect(resp).to eq 'Prison'
    end

    it "NPS allocations with no release date" do
      resp = described_class.calculate_case_owner(offender_nps_no_release_date)
      expect(resp).to eq 'No release date'
    end

    it "No allocation" do
      resp = described_class.calculate_case_owner(offender_none)
      expect(resp).to eq 'Unknown'
    end
  end

  describe 'pom responsibility' do
    it "is 'Responsible' if offender is Welsh and release date is greater than 10 months" do
      resp = described_class.calculate_pom_responsibility(offender_welsh_gt_10)
      expect(resp).to eq 'Responsible'
    end

    it "is 'Responsible' if offender is Welsh and release date is less than 10 months" do
      resp = described_class.calculate_pom_responsibility(offender_welsh_lt_10)
      expect(resp).to eq 'Supporting'
    end

    it "is 'Unknown' if offender has no release date" do
      resp = described_class.calculate_pom_responsibility(offender_nps_no_release_date)
      expect(resp).to eq 'Unknown'
    end
  end
end
