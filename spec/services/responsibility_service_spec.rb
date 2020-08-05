require 'rails_helper'

describe ResponsibilityService do
  describe '#calculate_pom_responsibility' do
    context 'when an immigration offender' do
      let(:offender) {
        OpenStruct.new immigration_case?: true
      }

      it 'will show the POM as supporting' do
        resp = described_class.calculate_pom_responsibility(offender)

        expect(resp).to eq ResponsibilityService::SUPPORTING
      end
    end

    context 'when an offender has been recalled' do
      let(:offender) {
        OpenStruct.new recalled?: true,
                       automatic_release_date: Time.zone.today
      }

      it 'will show the POM as supporting' do
        resp = described_class.calculate_pom_responsibility(offender)

        expect(resp).to eq ResponsibilityService::SUPPORTING
      end
    end

    context 'when an offender has been recalled & does not have any relevant release dates' do
      let(:offender) {
        OpenStruct.new recalled?: true
      }

      it 'will show the case as POM supporting' do
        resp = described_class.calculate_pom_responsibility(offender)

        expect(resp).to eq ResponsibilityService::SUPPORTING
      end
    end

    context 'when relevant release dates are missing' do
      let(:offender) {
        OpenStruct.new immigration_case?: false,
                       indeterminate_sentence?: false,
                       automatic_release_date: nil,
                       conditional_release_date: nil,
                       home_detention_curfew_eligibility_date: nil,
                       parole_eligibility_date: nil,
                       sentenced?: true
      }

      it 'will default to responsible' do
        resp = described_class.calculate_pom_responsibility(offender)

        expect(resp).to eq ResponsibilityService::RESPONSIBLE
      end
    end

    context 'when indeterminate with no tariff date' do
      let(:offender) {
        OpenStruct.new immigration_case?: false,
                       indeterminate_sentence?: true,
                       tariff_date: nil,
                       sentenced?: true
      }

      it 'will default to responsible' do
        expect(described_class.calculate_pom_responsibility(offender)).to eq ResponsibilityService::RESPONSIBLE
      end
    end

    context 'when incorrect service provider entered for indeterminate offender' do
      let(:offender) {
        OpenStruct.new  nps_case?: false,
                        welsh_offender: false,
                        indeterminate_sentence?: true,
                        sentence_start_date: Time.zone.today,
                        tariff_date: Time.zone.today + 24.months,
                        sentenced?: true
      }

      it 'will calculate the responsibility using NPS rules' do
        resp = described_class.calculate_pom_responsibility(offender)
        expect(resp).to eq ResponsibilityService::RESPONSIBLE
      end
    end

    context 'when CRC case' do
      # CRC rules do not take into account whether the offender is located at an open or closed prison, the rules
      # remain the same
      context 'when an offender is in a public prison' do
        let(:offender) {
          OpenStruct.new  nps_case?: false,
                          welsh_offender: false,
                          sentence_start_date: Time.zone.today,
                          automatic_release_date: ard,
                          conditional_release_date: crd,
                          home_detention_curfew_actual_date: hdcad,
                          home_detention_curfew_eligibility_date: hdced
        }

        context 'with less than 12 weeks left to serve with home_detention_curfew_eligibility_date' do
          let(:ard)   { nil }
          let(:crd)   { nil }
          let(:hdcad) { nil }
          let(:hdced) { Time.zone.today + 10.weeks }

          it 'will show the POM as having a supporting role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::SUPPORTING
          end
        end

        context 'with less than 12 weeks left to serve with conditional_release_date' do
          let(:ard)   { Time.zone.today + 15.weeks }
          let(:crd)   { Time.zone.today + 11.weeks }
          let(:hdcad) { nil }
          let(:hdced) { nil }

          it 'will show the POM as having a supporting role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::SUPPORTING
          end
        end

        context 'with less than 12 weeks left to serve with home_detention_curfew_actual_date' do
          let(:ard)   { nil }
          let(:crd)   { nil }
          let(:hdcad) { Time.zone.today + 9.weeks }
          let(:hdced) { Time.zone.today + 14.weeks }

          it 'will show the POM as having a supporting role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::SUPPORTING
          end
        end

        context 'when more than 12 weeks left to serve with home_detention_curfew_eligibility_date' do
          let(:ard)   { nil }
          let(:crd)   { nil }
          let(:hdcad) { nil }
          let(:hdced) { Time.zone.today + 15.weeks }

          it 'will show the POM as having a responsible role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::RESPONSIBLE
          end
        end

        context 'when more than 12 weeks left to serve with conditional_release_date' do
          let(:ard)   { Time.zone.today + 15.weeks }
          let(:crd)   { Time.zone.today + 14.weeks }
          let(:hdcad) { nil }
          let(:hdced) { nil }

          it 'will take the earliest date of either the ARD or CRD and show the POM as having a responsible role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::RESPONSIBLE
          end
        end

        context 'when more than 12 weeks left to serve with home_detention_curfew_actual_date' do
          let(:ard)   { nil }
          let(:crd)   { nil }
          let(:hdcad) { Time.zone.today + 14.weeks }
          let(:hdced) { nil }

          it 'will show the POM as having a responsible role' do
            resp = described_class.calculate_pom_responsibility(offender)
            expect(resp).to eq ResponsibilityService::RESPONSIBLE
          end
        end
      end
    end

    context 'when NPS case' do
      context 'when an open prison' do
        let(:offender) {
          OpenStruct.new prison_id: 'HDI',
                         nps_case?: true,
                         sentenced?: true
        }

        it 'will show the POM as supporting' do
          resp = described_class.calculate_pom_responsibility(offender)

          expect(resp).to eq ResponsibilityService::SUPPORTING
        end
      end

      context 'when an English offender' do
        context 'when sentenced before policy start date' do
          let(:sentence_start_date) { Date.parse('15-09-2019') }

          context 'when the prison is a hub' do
            let(:offender) {
              OpenStruct.new  prison_id: 'VEI',
                              nps_case?: true,
                              welsh_offender: false,
                              sentence_start_date: sentence_start_date,
                              automatic_release_date: ard,
                              conditional_release_date: crd,
                              sentenced?: true
            }

            context 'with over 20 months left to serve' do
              let(:ard)   { sentence_start_date + 21.months }
              let(:crd)   { sentence_start_date + 22.months }

              it 'is responsible' do
                resp = described_class.calculate_pom_responsibility(offender)

                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 20 months left to serve' do
              let(:ard)   { sentence_start_date + 11.months }
              let(:crd)   { sentence_start_date + 10.months }

              it 'is responsible' do
                resp = described_class.calculate_pom_responsibility(offender)

                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end

            context 'when the CRD and ARD are missing' do
              let(:ard) { nil }
              let(:crd) { nil }

              it 'will return no responsibility' do
                expect(described_class.calculate_pom_responsibility(offender)).
                  to be_nil
              end
            end
          end

          context 'when the prison is private' do
            let(:offender) {
              OpenStruct.new  prison_id: 'TSI',
                              nps_case?: true,
                              welsh_offender: false,
                              sentence_start_date: sentence_start_date,
                              automatic_release_date: ard,
                              conditional_release_date: nil,
                              sentenced?: true
            }

            context 'with expected release on the cutoff date' do
              let(:ard) { '1 June 2021'.to_date }

              it 'returns responsible' do
                resp = described_class.calculate_pom_responsibility(offender)

                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with expected release before the cutoff date' do
              let(:ard) { '31 May 2021'.to_date }

              it 'returns supporting' do
                resp = described_class.calculate_pom_responsibility(offender)

                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when a determinate NPS offender' do
            let(:offender) {
              OpenStruct.new(
                nps_case?: true,
                welsh_offender: false,
                sentence_start_date: sentence_start_date,
                automatic_release_date: ard,
                conditional_release_date: nil,
                sentenced?: true
              )
            }

            context 'when release date greater than cutoff date and within the handover window' do
              let(:ard) { '16 Feb 2021'.to_date }

              it 'returns supporting' do
                Timecop.travel('20 Dec 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::SUPPORTING
                end
              end
            end

            context 'when release date greater than cutoff date and before the handover window' do
              let(:ard) { '16 Feb 2021'.to_date }

              it 'returns responsible' do
                Timecop.travel('20 Sep 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::RESPONSIBLE
                end
              end
            end

            context 'when released date less than cutoff date' do
              let(:ard) { '16 Jan 2021'.to_date }

              it 'returns supporting' do
                Timecop.travel('16 Jan 2021') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::SUPPORTING
                end
              end
            end

            context 'when the release dates are missing' do
              let(:ard) { nil }

              it 'will return no responsibility' do
                expect(described_class.calculate_pom_responsibility(offender)).
                  to be_nil
              end
            end
          end

          context 'when a determinate NPS offender with parole eligibility' do
            let(:sentence_start_date) { Date.parse('15-09-2019') }
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: false,
                              indeterminate_sentence?: false,
                              sentence_start_date: sentence_start_date,
                              parole_eligibility_date: ped,
                              sentenced?: true
            }

            context 'with more than 17 months left to serve' do
              let(:ped) { sentence_start_date + 19.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 17 months left to serve' do
              let(:ped) { sentence_start_date + 6.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when an indeterminate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: false,
                              indeterminate_sentence?: true,
                              sentence_start_date: sentence_start_date,
                              tariff_date: ted,
                              sentenced?: true
            }

            context 'with more than 17 months left to serve and handover in future' do
              let(:ted) { sentence_start_date + 18.months }

              it 'will show the POM as having a responsible role' do
                resp = Timecop.travel Date.new(2020, 6, 1) do
                  described_class.calculate_pom_responsibility(offender)
                end

                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ted) { Time.zone.today + 4.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end
        end

        context 'when sentenced after policy start date' do
          context 'when a determinate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: false,
                              sentence_start_date: Time.zone.today,
                              automatic_release_date: ard,
                              conditional_release_date: crd
            }

            context 'with more than 10 months left to serve' do
              let(:ard)   { Time.zone.today + 14.months }
              let(:crd)   { Time.zone.today + 15.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ard)   { Time.zone.today + 6.months }
              let(:crd)   { Time.zone.today + 7.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when a determinate NPS offender with parole eligibility' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: false,
                              indeterminate_sentence?: false,
                              sentence_start_date: Time.zone.today,
                              parole_eligibility_date: ped
            }

            context 'with more than 10 months left to service' do
              let(:ped) { Time.zone.today + 12.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ped) { Time.zone.today + 6.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when an indeterminate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: false,
                              indeterminate_sentence?: true,
                              sentence_start_date: Time.zone.today,
                              tariff_date: ted
            }

            context 'with more than 10 months left to serve' do
              let(:ted) { Time.zone.today + 14.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ted) { Time.zone.today + 4.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end
        end
      end

      context 'when a Welsh offender' do
        context 'when sentenced before policy start date' do
          let(:sentence_start_date) { Date.parse('03-02-2019') }

          context 'when a determinate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              sentence_start_date: sentence_start_date,
                              automatic_release_date: ard,
                              conditional_release_date: nil,
                              sentenced?: true
            }

            context 'when release date greater than cutoff date and within the handover window' do
              let(:ard) { '20 May 2020'.to_date }

              it 'returns supporting' do
                Timecop.travel('20 Apr 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::SUPPORTING
                end
              end
            end

            context 'when release date greater than cutoff date and before the handover window' do
              let(:ard) { '20 May 2020'.to_date }

              it 'returns responsible' do
                Timecop.travel('1 Jan 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::RESPONSIBLE
                end
              end
            end

            context 'when released date less than cutoff date' do
              let(:ard) { '1 May 2020'.to_date }

              it 'returns supporting' do
                Timecop.travel('1 Apr 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::SUPPORTING
                end
              end
            end

            context 'when the CRD and ARD are missing' do
              let(:ard) { nil }

              it 'will return no responsibility' do
                expect(described_class.calculate_pom_responsibility(offender)).
                  to be_nil
              end
            end
          end

          context 'when a determinate NPS offender with parole eligibility' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              indeterminate_sentence?: false,
                              sentence_start_date: Time.zone.today,
                              parole_eligibility_date: ped,
                              sentenced?: true
            }

            context 'with more than 10 months left to serve' do
              let(:ped) { Time.zone.today + 12.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ped) { Time.zone.today + 6.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when an indeterminate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              indeterminate_sentence?: true,
                              sentence_start_date: sentence_start_date,
                              tariff_date: ted,
                              sentenced?: true
            }

            context 'with more than 15 months left to serve' do
              let(:ted) { sentence_start_date + 18.months }

              context 'when within the handover window' do
                it 'will show the POM as having a supporting role' do
                  Timecop.travel('5 May 2020') do
                    resp = described_class.calculate_pom_responsibility(offender)
                    expect(resp).to eq ResponsibilityService::SUPPORTING
                  end
                end
              end

              context 'when outside the handover window' do
                it 'will show the POM as having a responsible role' do
                  Timecop.travel('1 Nov 2019') do
                    resp = described_class.calculate_pom_responsibility(offender)
                    expect(resp).to eq ResponsibilityService::RESPONSIBLE
                  end
                end
              end
            end

            context 'with less than 15 months left to serve' do
              let(:ted) { sentence_start_date + 14.months }

              it 'will show the POM as having a supporting role' do
                Timecop.travel('1 March 2020') do
                  resp = described_class.calculate_pom_responsibility(offender)
                  expect(resp).to eq ResponsibilityService::SUPPORTING
                end
              end
            end
          end
        end

        context 'when sentenced after policy start date' do
          context 'when a determinate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              sentence_start_date: Time.zone.today,
                              automatic_release_date: ard,
                              conditional_release_date: crd,
                              sentenced?: true
            }

            context 'with more than 10 months left to serve' do
              let(:ard)   { Time.zone.today + 14.months }
              let(:crd)   { Time.zone.today + 15.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ard)   { Time.zone.today + 6.months }
              let(:crd)   { Time.zone.today + 7.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when a determinate NPS offender with parole eligibility' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              indeterminate_sentence?: false,
                              sentence_start_date: Time.zone.today,
                              parole_eligibility_date: ped,
                              sentenced?: true
            }

            context 'with more than 10 months left to service' do
              let(:ped) { Time.zone.today + 12.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ped) { Time.zone.today + 6.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end

          context 'when an indeterminate NPS offender' do
            let(:offender) {
              OpenStruct.new  nps_case?: true,
                              welsh_offender: true,
                              indeterminate_sentence?: true,
                              sentence_start_date: Time.zone.today,
                              tariff_date: ted,
                              sentenced?: true
            }

            context 'with more than 10 months left to serve' do
              let(:ted) { Time.zone.today + 14.months }

              it 'will show the POM as having a responsible role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::RESPONSIBLE
              end
            end

            context 'with less than 10 months left to serve' do
              let(:ted) { Time.zone.today + 4.months }

              it 'will show the POM as having a supporting role' do
                resp = described_class.calculate_pom_responsibility(offender)
                expect(resp).to eq ResponsibilityService::SUPPORTING
              end
            end
          end
        end
      end
    end
  end
end
