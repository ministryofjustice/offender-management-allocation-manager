require 'rails_helper'

describe ResponsibilityService do
  describe '#calculate_pom_responsibility' do
    context 'when a determinate NPS offender (new case)' do
      context 'with more than 10 months left to serve' do
        let(:offender) {
          OpenStruct.new  conditional_release_date: Time.zone.today + 15.months,
                          automatic_release_date: Time.zone.today + 14.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end

      context 'with less than 10 months left to serve' do
        let(:offender) {
          OpenStruct.new  conditional_release_date: Time.zone.today + 7.months,
                          automatic_release_date: Time.zone.today + 6.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end
    end

    context 'when a determinate NPS offender with parole eligibility (new case)' do
      context 'with more than 10 months left to service' do
        let(:offender) {
          OpenStruct.new  parole_eligibility_date: Time.zone.today + 12.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end

      context 'with less than 10 months left to serve' do
        let(:offender) {
          OpenStruct.new  parole_eligibility_date: Time.zone.today + 6.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end
    end

    context 'when CRC (new case)' do
      context 'with less than 12 weeks left to serve with home_detention_curfew_eligibility_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_eligibility_date: Time.zone.today + 10.weeks,
                          conditional_release_date: nil,
                          automatic_release_date: nil,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end

      context 'with less than 12 weeks left to serve with conditional_release_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_eligibility_date: nil,
                          conditional_release_date: Time.zone.today + 11.weeks,
                          automatic_release_date: Time.zone.today + 15.weeks,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end

      context 'with less than 12 weeks left to serve with home_detention_curfew_actual_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_actual_date: Time.zone.today + 9.weeks,
                          conditional_release_date: nil,
                          automatic_release_date: nil,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end

      context 'when more than 12 weeks left to serve with home_detention_curfew_eligibility_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_eligibility_date: Time.zone.today + 15.weeks,
                          conditional_release_date: nil,
                          automatic_release_date: nil,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end

      context 'when more than 12 weeks left to serve with conditional_release_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_eligibility_date: nil,
                          conditional_release_date: Time.zone.today + 14.weeks,
                          automatic_release_date: Time.zone.today + 15.weeks,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end

      context 'when more than 12 weeks left to serve with home_detention_curfew_actual_date' do
        let(:offender) {
          OpenStruct.new  sentence_start_date: Time.zone.today,
                          home_detention_curfew_actual_date: Time.zone.today + 14.weeks,
                          conditional_release_date: nil,
                          automatic_release_date: nil,
                          nps_case?: false,
                          welsh_offender?: false
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end
    end

    context 'when an indeterminate NPS offender (new case)' do
      context 'with more than 10 months left to serve' do
        let(:offender) {
          OpenStruct.new  tariff_date: Time.zone.today + 14.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false,
                          indeterminate_sentence?: true
        }

        it 'will show the POM as having a responsible role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::RESPONSIBLE
        end
      end

      context 'with less than 10 months left to serve' do
        let(:offender) {
          OpenStruct.new  tariff_date: Time.zone.today + 4.months,
                          sentence_start_date: Time.zone.today,
                          nps_case?: true,
                          welsh_offender?: false,
                          indeterminate_sentence?: true
        }

        it 'will show the POM as having a supporting role' do
          resp = described_class.calculate_pom_responsibility(offender)
          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end
    end
  end
end

# describe ResponsibilityService do
#   describe '#calculate_pom_responsibility' do
#     context 'when the offender is an immigration case' do
#       let(:offender) {
#         OpenStruct.new immigration_case?: true,
#                        determinate_sentence?: true,
#                        recalled?: false
#       }

#       it 'is responsible' do
#         resp = described_class.calculate_pom_responsibility(offender)

#         expect(resp).to eq ResponsibilityService::SUPPORTING
#       end
#     end

#     context 'when indeterminate with dates in the past' do
#       let(:offender) {
#         OpenStruct.new indeterminate_sentence?: true,
#                        recalled?: false,
#                        earliest_release_date: Time.zone.today - 1.year,
#                        sentenced?: true
#       }

#       it 'is responsible' do
#         resp = described_class.calculate_pom_responsibility(offender)

#         expect(resp).to eq ResponsibilityService::RESPONSIBLE
#       end
#     end

#     context 'when an NPS offender is in an open prison' do
#       let(:offender) {
#         OpenStruct.new prison_id: 'HDI',
#                        nps_case?: true,
#                        indeterminate_sentence?: true,
#                        recalled?: false,
#                        earliest_release_date: Time.zone.today - 1.year,
#                        sentenced?: true
#       }

#       it 'is supporting/community' do
#         resp = described_class.calculate_pom_responsibility(offender)

#         expect(resp).to eq ResponsibilityService::SUPPORTING
#       end
#     end

#     context 'when offender is english' do
#       let(:offender) {
#         OpenStruct.new welsh_offender: false,
#                        nps_case?: case_allocation == 'NPS',
#                        indeterminate_sentence?: false,
#                        recalled?: recalled,
#                        sentence_start_date: start_date,
#                        automatic_release_date: release_date,
#                        conditional_release_date: release_date - 1.day,
#                        parole_eligibility_date: parole_date,
#                        sentenced?: true,
#                        prison_id: prison
#       }

#       let(:parole_date) { nil }
#       let(:recalled) { false }
#       let(:prison) { 'LEI' }

#       context 'when (old case) sentenced before 30th Sept' do
#         let(:start_date) { Date.new(2019, 9, 18) }

#         context 'when NPS' do
#           let(:case_allocation) { 'NPS' }

#           context 'when in PSP (public service prison)' do
#             context 'with > 16.5 months left to serve' do
#               let(:release_date) { Date.new(2019, 10, 1) + 16.months + 3.weeks }

#               it 'is responsible' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::RESPONSIBLE
#               end
#             end

#             context 'with < 16.5 months left' do
#               let(:release_date) { Date.new(2019, 10, 1) + 16.months + 2.weeks }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           context 'when in a hub model prison' do
#             let(:prison) { 'VEI' }

#             context 'with over 20 months left to serve' do
#               let(:release_date) { Date.new(2019, 10, 1) + 21.months }

#               it 'is responsible' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::RESPONSIBLE
#               end
#             end

#             context 'with < 20 months left' do
#               let(:release_date) { Date.new(2019, 10, 1) + 19.months }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           context 'when in a private prison' do
#             let(:prison) { 'TSI' }

#             context 'with over 20 months left to serve' do
#               let(:release_date) { Date.new(2019, 10, 1) + 21.months }

#               it 'is responsible' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::RESPONSIBLE
#               end
#             end

#             context 'with < 20 months left' do
#               let(:release_date) { Date.new(2019, 10, 1) + 19.months }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           context 'when inderminate' do
#             let(:release_date) { parole_date }
#             let(:inderminate_sentence) { true }

#             context 'with ped > 17 months away' do
#               let(:parole_date) { DateTime.now.utc.to_date + 18.months }

#               it 'is responsible' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::RESPONSIBLE
#               end
#             end

#             context 'with ped < 17 months away' do
#               let(:parole_date) { DateTime.now.utc.to_date + 16.months }
#               let(:release_date) { Date.new(2020, 9, 18) }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end
#         end

#         context 'when CRC' do
#           let(:case_allocation) { 'CRC' }

#           context 'with > 12 weeks left to serve' do
#             let(:release_date) { DateTime.now.utc.to_date + 13.weeks }

#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end
#           end

#           context 'with < 12 weeks left to serve' do
#             let(:release_date) { DateTime.now.utc.to_date + 11.weeks }

#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end

#         context 'when recalled' do
#           let(:release_date) { Date.new(2019, 12, 1) }
#           let(:recalled) { true }

#           %w[NPS CRC].each do |case_allocation|
#             let(:case_allocation) { case_allocation }

#             it 'is always supporting' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end
#       end

#       context 'when (new case) sentenced after 1st Oct' do
#         let(:start_date) { Date.new(2019, 10, 18) }

#         context 'when NPS' do
#           let(:case_allocation) { 'NPS' }

#           context 'when < 10 months left to serve' do
#             let(:release_date) { start_date + 9.months }

#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end

#           context 'when > 10 months left to serve' do
#             let(:release_date) { start_date + 11.months }
#             let(:parole_date) { release_date }

#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end

#             it 'is supporting on the handover date' do
#               Timecop.travel start_date + 9.months do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           context 'when indeterminate' do
#             let(:release_date) { nil }

#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end
#           end
#         end

#         context 'when CRC' do
#           let(:offender) {
#             OpenStruct.new nps_case?: false,
#                            recalled?: false,
#                            sentence_start_date: start_date,
#                            earliest_release_date: release_date,
#                            home_detention_curfew_eligibility_date: hdc_date,
#                            sentenced?: true,
#                            prison_id: prison
#           }

#           context 'with > 12 weeks left to serve' do
#             let(:release_date) { DateTime.now.utc.to_date + 13.weeks }
#             let(:hdc_date) { nil }

#             it 'is reponsible' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end

#             context 'when HDC date within the 12 weeks' do
#               let(:hdc_date) { DateTime.now.utc.to_date + 11.weeks }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           context 'with < 12 weeks left to serve' do
#             let(:release_date) { DateTime.now.utc.to_date + 11.weeks }
#             let(:hdc_date) { nil }

#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end

#         context 'when recalled' do
#           let(:release_date) { Date.new(2020, 12, 1) }
#           let(:recalled) { true }

#           context 'when determinate' do
#             let(:inderminate) { false }

#             context 'when NPS' do
#               let(:case_allocation) { 'NPS' }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end

#             context 'when CRC' do
#               let(:case_allocation) { 'CRC' }

#               it 'is supporting' do
#                 resp = described_class.calculate_pom_responsibility(offender)

#                 expect(resp).to eq ResponsibilityService::SUPPORTING
#               end
#             end
#           end

#           # CRC indeterminate recall shouldn't be possible.
#           context 'when indeterminate' do
#             let(:case_allocation) { 'NPS' }
#             let(:inderminate) { true }

#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end
#       end
#     end

#     context 'when offender is Welsh' do
#       context 'when recalled' do
#         let(:offender) {
#           OpenStruct.new welsh_offender: true,
#                          recalled?: true,
#                          earliest_release_date: Date.new(2021, 1, 2),
#                          sentenced?: true
#         }

#         it 'is always supporting' do
#           resp = described_class.calculate_pom_responsibility(offender)

#           expect(resp).to eq ResponsibilityService::SUPPORTING
#         end
#       end

#       context 'when CRC case' do
#         let(:offender) {
#           Nomis::Offender.new(inprisonment_status: 'SENT_EXL',
#                               welsh_offender: true,
#                               case_allocation: 'CRC'
#                               ).tap { |o|
#             o.sentence = Nomis::SentenceDetail.new
#             o.sentence.release_date = release_date
#           }
#         }

#         context 'when offender has less than 12 weeks to serve' do
#           let(:release_date) { DateTime.now.utc.to_date + 2.weeks }

#           it 'is supporting' do
#             resp = described_class.calculate_pom_responsibility(offender)

#             expect(resp).to eq ResponsibilityService::SUPPORTING
#           end
#         end

#         context 'when offender has more than twelve weeks to serve' do
#           let(:release_date) { DateTime.now.utc.to_date + 13.weeks }

#           it 'is responsible' do
#             resp = described_class.calculate_pom_responsibility(offender)

#             expect(resp).to eq ResponsibilityService::RESPONSIBLE
#           end
#         end
#       end

#       context 'when NPS case' do
#         context 'when new case (sentence date after February 4 2019)' do
#           let(:offender_welsh_nps_new_case_gt_10_mths) {
#             Nomis::Offender.new(inprisonment_status: 'UNK_SENT').tap { |o|
#               o.welsh_offender = true
#               o.case_allocation = 'NPS'
#               o.sentence = Nomis::SentenceDetail.new
#               o.sentence.sentence_start_date = DateTime.new(2019, 2, 19).utc
#               o.sentence.release_date = DateTime.now.utc.to_date + 11.months
#               o.sentence.conditional_release_date = o.sentence.release_date
#             }
#           }

#           let(:offender_welsh_nps_new_case_lt_10_mths) {
#             Nomis::Offender.new(inprisonment_status: 'UNK_SENT').tap { |o|
#               o.welsh_offender = true
#               o.case_allocation = 'NPS'
#               o.sentence = Nomis::SentenceDetail.new
#               o.sentence.sentence_start_date = DateTime.new(2019, 2, 20).utc
#               o.sentence.release_date = DateTime.now.utc.to_date + 9.months
#               o.sentence.conditional_release_date = o.sentence.sentence_start_date + 8.months
#             }
#           }

#           context 'when time left to serve is greater than 10 months' do
#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_new_case_gt_10_mths)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end
#           end

#           context 'when time left to serve is less than 10 months' do
#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_new_case_lt_10_mths)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end

#         context 'when old case (sentence date before February 4 2019)' do
#           let(:offender_welsh_nps_old_case_gt_15_mths) {
#             Nomis::Offender.new(inprisonment_status: 'UNK_SENT').tap { |o|
#               o.welsh_offender = true
#               o.case_allocation = 'NPS'
#               o.sentence = Nomis::SentenceDetail.new
#               o.sentence.sentence_start_date = DateTime.new(2019, 1, 19).utc
#               o.sentence.release_date = Date.new(2019, 2, 4) + 16.months
#             }
#           }

#           let(:offender_welsh_nps_old_case_lt_15_mths) {
#             Nomis::Offender.new(inprisonment_status: 'UNK_SENT').tap { |o|
#               o.welsh_offender = true
#               o.case_allocation = 'NPS'
#               o.sentence = Nomis::SentenceDetail.new
#               o.sentence.sentence_start_date = DateTime.new(2019, 1, 20).utc
#               o.sentence.release_date = Date.new(2019, 2, 4) + 14.months
#             }
#           }

#           context 'when time left to serve is greater than 15 months from February 4 2019' do
#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_gt_15_mths)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end
#           end

#           context 'when time left to serve is less than 15 months from February 4 2019' do
#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_lt_15_mths)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end
#       end
#     end
#   end
# end
#           context 'when time left to serve is greater than 15 months from February 4 2019' do
#             it 'is responsible' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_gt_15_mths)

#               expect(resp).to eq ResponsibilityService::RESPONSIBLE
#             end
#           end

#           context 'when time left to serve is less than 15 months from February 4 2019' do
#             it 'is supporting' do
#               resp = described_class.calculate_pom_responsibility(offender_welsh_nps_old_case_lt_15_mths)

#               expect(resp).to eq ResponsibilityService::SUPPORTING
#             end
#           end
#         end
#       end
#     end
#   end
# end
