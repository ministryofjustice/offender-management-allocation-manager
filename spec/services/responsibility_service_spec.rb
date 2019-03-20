require 'rails_helper'

describe ResponsibilityService do
  let(:offender_none) {
    Nomis::Models::Offender.new
  }
  let(:offender_crc) {
    Nomis::Models::Offender.new.tap { |o| o.case_allocation = 'CRC' }
  }
  let(:offender_nps_gt_10) {
    Nomis::Models::Offender.new.tap { |o|
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 12.months
    }
  }
  let(:offender_nps_lt_10) {
    Nomis::Models::Offender.new.tap { |o|
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 6.months
    }
  }

  let(:offender_nps_no_release_date) {
    Nomis::Models::Offender.new.tap { |o| o.case_allocation = 'NPS' }
  }

  let(:offender_no_release_date) {
    Nomis::Models::Offender.new.tap { |o|
      o.release_date = nil
    }
  }

  let(:offender_not_welsh) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = false
      o.release_date = DateTime.now.utc.to_date + 6.months
    }
  }

  let(:offender_welsh_crc_lt_12_wk) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'CRC'
      o.release_date = DateTime.now.utc.to_date + 2.weeks
    }
  }

  let(:offender_welsh_crc_gt_12_wk) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'CRC'
      o.release_date = DateTime.now.utc.to_date + 13.weeks
    }
  }

  let(:offender_welsh_nps_gt_10_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 11.months
    }
  }

  let(:offender_welsh_nps_lt_10_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  let(:offender_welsh_nps_old_case_gt_15_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence_date = DateTime.new(2019, 1, 19).utc
      o.release_date = DateTime.now.utc.to_date + 16.months
    }
  }

  let(:offender_welsh_nps_old_case_lt_15_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence_date = DateTime.new(2019, 2, 20).utc
      o.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  let(:offender_welsh_nps_new_case_gt_10_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence_date = DateTime.new(2019, 1, 19).utc
      o.release_date = DateTime.now.utc.to_date + 16.months
    }
  }

  let(:offender_welsh_nps_new_case_lt_10_mths) {
    Nomis::Models::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence_date = DateTime.new(2019, 2, 20).utc
      o.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  describe 'case owner' do
    it "CRC allocations means Prison" do
      resp = subject.calculate_case_owner(offender_crc)
      expect(resp).to eq 'Prison'
    end

    it "NPS allocations with no release date" do
      resp = subject.calculate_case_owner(offender_nps_no_release_date)
      expect(resp).to eq 'No release date'
    end

    it "No allocation" do
      resp = subject.calculate_case_owner(offender_none)
      expect(resp).to eq 'Unknown'
    end
  end

  describe 'pom responsibility' do
    context 'when offender has no release date' do
      scenario 'is supporting' do
        resp = subject.calculate_pom_responsibility(offender_no_release_date)

        expect(resp).to eq 'Unknown'
      end
    end

    context 'when offender is not Welsh' do
      scenario 'is supporting' do
        resp = subject.calculate_pom_responsibility(offender_not_welsh)

        expect(resp).to eq 'Supporting'
      end
    end

    context 'when offender is Welsh' do
      context 'when CRC case' do
        context 'when offender has less than 12 weeks to serve' do
          scenario 'is supporting' do
            resp = subject.calculate_pom_responsibility(offender_welsh_crc_lt_12_wk)

            expect(resp).to eq 'Supporting'
          end
        end

        context 'when offender has more than twelve weeks to serve' do
          scenario 'is responsible' do
            resp = subject.calculate_pom_responsibility(offender_welsh_crc_gt_12_wk)

            expect(resp).to eq 'Responsible'
          end
        end
      end

      context 'when NPS case' do
        context 'when new case (sentence date after February 4 2019)' do
          context 'when time left to serve is greater than 10 months' do
            scenario 'is responsible' do
              resp = subject.calculate_pom_responsibility(offender_welsh_nps_new_case_gt_10_mths)

              expect(resp).to eq 'Responsible'
            end
          end

          context 'when time left to serve is less than 10 months' do
            scenario 'is supporting' do
              resp = subject.calculate_pom_responsibility(offender_welsh_nps_new_case_lt_10_mths)

              expect(resp).to eq 'Supporting'
            end
          end
        end

        context 'when old case (sentence date before February 4 2019)' do
          context 'when time left to serve is greater than 15 months from February 4 2019' do
            scenario 'is responsible' do
              resp = subject.calculate_pom_responsibility(offender_welsh_nps_old_case_gt_15_mths)

              expect(resp).to eq 'Responsible'
            end
          end

          context 'when time left to serve is less than 15 months from February 4 2019' do
            scenario 'is supporting' do
              resp = subject.calculate_pom_responsibility(offender_welsh_nps_old_case_lt_15_mths)

              expect(resp).to eq 'Supporting'
            end
          end
        end
      end
    end
  end
end
