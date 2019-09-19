require 'rails_helper'

describe ResponsibilityService do
  let(:offender_no_release_date) {
    Nomis::Offender.new.tap { |o|
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = nil
    }
  }

  let(:offender_not_welsh) {
    Nomis::Offender.new.tap { |o|
      o.omicable = false
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = DateTime.now.utc.to_date + 6.months
    }
  }

  let(:offender_welsh_crc_lt_12_wk) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'CRC'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = DateTime.now.utc.to_date + 2.weeks
    }
  }

  let(:offender_welsh_crc_gt_12_wk) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'CRC'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = DateTime.now.utc.to_date + 13.weeks
    }
  }

  let(:offender_welsh_nps_gt_10_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = DateTime.now.utc.to_date + 11.months
    }
  }

  let(:offender_welsh_nps_lt_10_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  let(:offender_welsh_nps_old_case_gt_15_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.sentence_start_date = DateTime.new(2019, 1, 19).utc
      o.sentence.release_date = DateTime.now.utc.to_date + 16.months
    }
  }

  let(:offender_welsh_nps_old_case_lt_15_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.sentence_start_date = DateTime.new(2019, 2, 20).utc
      o.sentence.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  let(:offender_welsh_nps_new_case_gt_10_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.sentence_start_date = DateTime.new(2019, 1, 19).utc
      o.sentence.release_date = DateTime.now.utc.to_date + 16.months
    }
  }

  let(:offender_welsh_nps_new_case_lt_10_mths) {
    Nomis::Offender.new.tap { |o|
      o.omicable = true
      o.case_allocation = 'NPS'
      o.sentence = Nomis::SentenceDetail.new
      o.sentence.sentence_start_date = DateTime.new(2019, 2, 20).utc
      o.sentence.release_date = DateTime.now.utc.to_date + 9.months
    }
  }

  describe 'pom responsibility' do
    context 'when offender has no release date' do
      scenario 'is supporting' do
        resp = described_class.calculate_pom_responsibility(offender_no_release_date)

        expect(resp).to eq 'Responsible'
      end
    end

    context 'when offender is not Welsh' do
      scenario 'is supporting' do
        resp = described_class.calculate_pom_responsibility(offender_not_welsh)

        expect(resp).to eq 'Supporting'
      end
    end

    context 'when offender is Welsh' do
      context 'when CRC case' do
        context 'when offender has less than 12 weeks to serve' do
          scenario 'is supporting' do
            resp = described_class.calculate_pom_responsibility(offender_welsh_crc_lt_12_wk)

            expect(resp).to eq 'Supporting'
          end
        end

        context 'when offender has more than twelve weeks to serve' do
          scenario 'is responsible' do
            resp = described_class.calculate_pom_responsibility(offender_welsh_crc_gt_12_wk)

            expect(resp).to eq 'Responsible'
          end
        end
      end

      context 'when NPS case' do
        context 'when new case (sentence date after February 4 2019)' do
          context 'when time left to serve is greater than 10 months' do
            scenario 'is responsible' do
              resp = described_class.calculate_pom_responsibility(offender_welsh_nps_new_case_gt_10_mths)

              expect(resp).to eq 'Responsible'
            end
          end

          context 'when time left to serve is less than 10 months' do
            scenario 'is supporting' do
              resp = described_class.calculate_pom_responsibility(offender_welsh_nps_new_case_lt_10_mths)

              expect(resp).to eq 'Supporting'
            end
          end
        end

        context 'when old case (sentence date before February 4 2019)' do
          context 'when time left to serve is greater than 15 months from February 4 2019' do
            scenario 'is responsible' do
              resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_gt_15_mths)

              expect(resp).to eq 'Responsible'
            end
          end

          context 'when time left to serve is less than 15 months from February 4 2019' do
            scenario 'is supporting' do
              resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_lt_15_mths)

              expect(resp).to eq 'Supporting'
            end
          end
        end
      end
    end
  end
end
