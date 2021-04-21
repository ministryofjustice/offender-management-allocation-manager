# frozen_string_literal: true

require 'rails_helper'

describe HandoverDateService do
  describe 'calculating when community start supporting custody' do
    subject do
      x = described_class.handover(offender)
      {
          start_date: x.start_date,
          handover_date: x.handover_date
      }
    end

    context 'when recalled' do
      let(:offender) { OpenStruct.new(recalled?: true) }

      it 'is not calculated' do
        expect(subject).to eq(start_date: nil, handover_date: nil)
      end
    end

    context 'when NPS' do
      let(:offender) {
        OpenStruct.new indeterminate_sentence?: indeterminate,
                       nps_case?: true,
                       sentence_start_date: automatic_release_date - 2.years,
                       automatic_release_date: automatic_release_date,
                       tariff_date: tariff_date
      }

      let(:automatic_release_date) { Date.new(2025, 8, 30) }
      let(:tariff_date) { Date.new(2025, 8, 30) }

      context 'with a determinate sentence' do
        let(:indeterminate) { false }

        it 'is 7.5 months before release date' do
          expect(subject).to eq(start_date: Date.new(2025, 1, 15), handover_date: Date.new(2025, 4, 15))
        end

        describe 'com_supporting?' do
          subject { described_class.handover(offender).community_supporting? }

          context 'when before start' do
            it 'is false' do
              Timecop.travel Date.new(2025, 1, 14) do
                expect(subject).to eq(false)
              end
            end
          end

          context 'when after end' do
            it 'is false' do
              Timecop.travel Date.new(2025, 4, 16) do
                expect(subject).to eq(false)
              end
            end
          end

          context 'when between dates' do
            it 'is true' do
              Timecop.travel Date.new(2025, 3, 16) do
                expect(subject).to eq(true)
              end
            end
          end
        end
      end

      context "with indeterminate sentence" do
        let(:indeterminate) { true }

        it 'is 8 months before release date' do
          expect(described_class.handover(offender).start_date).to eq(Date.new(2024, 12, 30))
        end

        context 'with no tariff date' do
          let(:tariff_date) { nil }

          it 'is not set' do
            expect(described_class.handover(offender).start_date).to be_nil
          end

          it 'is not community supporting' do
            expect(described_class.handover(offender).community_supporting?).to eq(false)
          end
        end
      end
    end

    context 'when CRC' do
      let(:offender) { OpenStruct.new(nps_case?: false) }

      it 'is not set' do
        expect(described_class.handover(offender).start_date).to be_nil
      end
    end

    context 'when incorrect service provider entered for indeterminate offender' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail, :indeterminate, tariffDate: tariff_date)).tap { |o|
          o.load_case_information(build(:case_information, :crc))
        }
      }

      let(:tariff_date) { Date.new(2030, 8, 30) }

      it 'is 8 months before release date' do
        expect(described_class.handover(offender).start_date).to eq(Date.new(2029, 12, 30))
      end
    end

    context 'with early allocation' do
      let(:crd) { Date.new(2021, 6, 2) }

      context 'when outside referral window' do
        let(:offender) {
          build(:offender,
                sentence: build(:sentence_detail, :determinate, :english_policy_sentence,
                                automaticReleaseDate: ard,
                                conditionalReleaseDate: crd)).tap { |o|
            o.load_case_information(case_info)
          }
        }
        let(:case_info) { build(:case_information, early_allocations: [build(:early_allocation, created_within_referral_window: false)]) }
        let(:ard) { nil }

        it 'will be unaffected' do
          expect(subject).to eq(start_date: Date.new(2020, 10, 18), handover_date: Date.new(2021, 1, 18))
        end
      end

      context 'when indeterminate' do
        let(:ted) { Date.new(2022, 7, 3) }
        let(:ted15) { ted - 15.months }

        let(:offender) {
          build(:offender,
                sentence: build(:sentence_detail, :indeterminate,
                                paroleEligibilityDate: ped,
                                tariffDate: ted)).tap { |o|
            o.load_case_information(case_info)
          }
        }
        let(:case_info) { build(:case_information, early_allocations: [build(:early_allocation, created_within_referral_window: true)]) }

        context 'without PED' do
          let(:ped) { nil }

          it 'will be 15 months before TED' do
            expect(subject).to eq(start_date: ted15, handover_date: ted15)
          end
        end

        context 'with earlier PED' do
          let(:ped) { Date.new(2022, 7, 2)  }

          it 'will still be 15 months before TED' do
            expect(subject).to eq(start_date: ted15, handover_date: ted15)
          end
        end
      end

      context 'when determinate' do
        let(:offender) {
          build(:offender,
                sentence: build(:sentence_detail, :determinate, :english_policy_sentence,
                                automaticReleaseDate: ard,
                                conditionalReleaseDate: crd)).tap { |o|
            o.load_case_information(case_info)
          }
        }

        context 'when inside referral window' do
          let(:case_info) { build(:case_information, early_allocations: [build(:early_allocation, created_within_referral_window: true)]) }

          context 'without ARD' do
            let(:ard) { nil }

            it 'will be 15 months before CRD' do
              expect(subject).to eq(start_date: Date.new(2020, 3, 2), handover_date: Date.new(2020, 3, 2))
            end
          end

          context 'with earlier ARD' do
            let(:ard) { Date.new(2021, 6, 1) }

            it 'will be 15 months before ARD' do
              expect(subject).to eq(start_date: Date.new(2020, 3, 1), handover_date: Date.new(2020, 3, 1))
            end
          end
        end

        context 'when outside referral window' do
          let(:case_info) { build(:case_information, early_allocations: [build(:early_allocation, created_within_referral_window: false)]) }
          let(:ard) { nil }

          it 'will be unaffected' do
            expect(subject).to eq(start_date: Date.new(2020, 10, 18), handover_date: Date.new(2021, 1, 18))
          end
        end
      end
    end
  end

  describe 'handover dates' do
    let(:result) { described_class.handover(offender).handover_date }
    let(:sentence_type_trait) {
      if indeterminate_sentence
        recall? ? :indeterminate_recall : :indeterminate
      else
        recall? ? :determinate_recall : :determinate
      end
    }

    let(:offender) do
      build(:offender,
            sentence: build(:sentence_detail, sentence_type_trait,
                            automaticReleaseDate: automatic_release_date,
                            conditionalReleaseDate: conditional_release_date,
                            paroleEligibilityDate: parole_date,
                            homeDetentionCurfewActualDate: home_detention_curfew_actual_date,
                            homeDetentionCurfewEligibilityDate: home_detention_curfew_eligibility_date,
                            tariffDate: tariff_date)).
          tap { |o| o.load_case_information(case_info) }
    end

    let(:automatic_release_date) { nil }
    let(:conditional_release_date) { nil }
    let(:home_detention_curfew_actual_date) { nil }
    let(:home_detention_curfew_eligibility_date) { nil }
    let(:parole_date) { nil }
    let(:mappa_level) { nil }
    let(:tariff_date) { nil }
    let(:indeterminate_sentence) { false }
    let(:early_allocation) { nil }
    let(:recall?) { false }

    context 'when CRC' do
      let(:case_info) { build(:case_information, :crc) }

      context 'when 12 weeks before the CRD date' do
        let(:automatic_release_date) { Date.new(2019, 8, 1) }
        let(:conditional_release_date) { Date.new(2019, 8, 12) }

        it 'will return the handover date 12 weeks before the CRD' do
          expect(result).to eq Date.new(2019, 5, 9)
        end
      end

      context 'when 12 weeks before the ARD date' do
        let(:automatic_release_date) { Date.new(2019, 8, 12) }
        let(:conditional_release_date) { Date.new(2019, 8, 1) }

        it 'will return the handover date 12 weeks before the ARD' do
          expect(result).to eq Date.new(2019, 5, 9)
        end
      end

      context 'when HDCED date is present' do
        let(:automatic_release_date) { Date.new(2019, 8, 1) }
        let(:conditional_release_date) { Date.new(2019, 8, 12) }
        let(:home_detention_curfew_eligibility_date) { Date.new(2019, 7, 25) }

        it 'the handover date will be on the HDCED date minus 12 weeks' do
          expect(result).to eq Date.new(2019, 5, 2)
        end
      end

      context 'when HDCAD date is present' do
        let(:automatic_release_date) { Date.new(2019, 8, 1) }
        let(:conditional_release_date) { Date.new(2019, 8, 12) }
        let(:home_detention_curfew_actual_date) { Date.new(2019, 7, 26) }
        let(:home_detention_curfew_eligibility_date) { Date.new(2019, 7, 25) }

        it 'the handover date will be on the HDCAD date minus 12 weeks' do
          expect(result).to eq Date.new(2019, 5, 3)
        end
      end

      context 'when there are no release related dates' do
        it 'will return no handover date' do
          expect(result).to be_nil
        end
      end
    end

    context 'when NPS' do
      context 'with normal allocation' do
        let(:case_info) { build(:case_information, :nps, mappa_level: mappa_level) }

        let(:tariff_date) { Date.new(2021, 11, 1) }
        let(:conditional_release_date) { Date.new(2021, 7, 16) }
        let(:automatic_release_date) { Date.new(2021, 8, 16) }

        context 'with determinate sentence' do
          let(:indeterminate_sentence) { false }

          context 'with parole eligibility' do
            let(:parole_date) { Date.new(2020, 9, 30) }

            it 'is 8 months before parole date' do
              expect(result).to eq(Date.new(2020, 1, 30))
            end
          end

          context 'when non-parole case' do
            context 'when mappa unknown' do
              let(:mappa_level) { nil }

              context 'when crd before ard' do
                it 'is 4.5 months before CRD' do
                  expect(result).to eq(Date.new(2021, 3, 1))
                end
              end

              context 'when HDCED is present and earlier than the ARD/CRD calculated date' do
                let(:home_detention_curfew_eligibility_date) {  Date.new(2021, 6, 16) }
                let(:automatic_release_date) { Date.new(2021, 11, 10) }
                let(:conditional_release_date) { Date.new(2021, 12, 5) }

                it 'is set to HDCED' do
                  expect(result).to eq(home_detention_curfew_eligibility_date)
                end
              end

              context 'when HDCAD is present' do
                let(:home_detention_curfew_eligibility_date) { Date.new(2021, 6, 16) }
                let(:home_detention_curfew_actual_date) { Date.new(2021, 6, 20) }

                it 'is set to HDCAD' do
                  expect(result).to eq(home_detention_curfew_actual_date)
                end
              end
            end

            context "with mappa level 0 (maapa doesn't apply)" do
              let(:mappa_level) { 0 }

              context 'when crd before ard' do
                it 'is 4.5 months before CRD' do
                  expect(result).to eq(Date.new(2021, 3, 1))
                end
              end

              context 'when crd after ard' do
                let(:conditional_release_date) { Date.new(2021, 8, 17) }

                it 'is 4.5 months before ARD' do
                  expect(result).to eq(Date.new(2021, 4, 1))
                end
              end

              context 'when HDC date earlier than the CRD/ARD calculated date' do
                let(:home_detention_curfew_eligibility_date) { Date.new(2021, 2, 28) }

                it 'is on HDC date' do
                  expect(result).to eq(Date.new(2021, 2, 28))
                end
              end

              context 'when HDCED date later than date indicated by CRD/ARD' do
                let(:home_detention_curfew_eligibility_date) { Date.new(2022, 2, 14) }

                it 'is 4.5 months before CRD' do
                  expect(result).to eq(Date.new(2021, 3, 1))
                end
              end

              context 'when HDCAD is present' do
                let(:home_detention_curfew_actual_date) { Date.new(2021, 2, 15) }
                let(:home_detention_curfew_eligibility_date) { Date.new(2021, 2, 28) }

                it 'is on HDCAD date' do
                  expect(result).to eq(Date.new(2021, 2, 15))
                end
              end
            end

            context 'with mappa level 1' do
              let(:mappa_level) { 1 }

              it 'is 4.5 months before CRD/ARD date or on HDC date' do
                expect(result).to eq(Date.new(2021, 3, 1))
              end
            end

            context 'with mappa level 2' do
              let(:mappa_level) { 2 }

              it 'is todays date' do
                expect(result).to eq(Time.zone.today)
              end

              context 'with release dates far in the future' do
                let(:conditional_release_date) { '20 Sept 2100'.to_date }
                let(:automatic_release_date) { '20 Sept 2100'.to_date }

                it 'returns 7.5 months before those release dates' do
                  expect(result).to eq('5 Feb 2100'.to_date)
                end
              end

              context 'with missing release dates' do
                let(:conditional_release_date) { nil }
                let(:automatic_release_date) { nil }

                it 'returns nil' do
                  expect(result).to be_nil
                end
              end
            end

            context 'with mappa level 3' do
              let(:mappa_level) { 3 }

              it 'is todays date' do
                expect(result).to eq(Time.zone.today)
              end

              context 'with release dates far in the future' do
                let(:conditional_release_date) { '20 Sept 2100'.to_date }
                let(:automatic_release_date) { '20 Sept 2100'.to_date }

                it 'returns 7.5 months before those release dates' do
                  expect(result).to eq('5 Feb 2100'.to_date)
                end
              end

              context 'with missing release dates' do
                let(:conditional_release_date) { nil }
                let(:automatic_release_date) { nil }

                it 'returns nil' do
                  expect(result).to be_nil
                end
              end
            end
          end
        end

        context "with indeterminate sentence" do
          let(:indeterminate_sentence) { true }

          context 'with tariff date in the future' do
            let(:tariff_date) { Date.new(2025, 11, 1) }

            it 'is 8 months before tariff date' do
              expect(result).to eq(Date.new(2025, 3, 1))
            end
          end

          context 'with no tariff date' do
            let(:tariff_date) { nil }

            it 'cannot be calculated' do
              expect(result).to be_nil
            end
          end
        end
      end
    end
  end

  describe '#nps_start_date' do
    let(:indeterminate_sentence) { false }
    let(:conditional_release_date) { nil }
    let(:parole_eligibility_date) { nil }
    let(:tariff_date) { nil }
    let(:automatic_release_date) { nil }

    let(:offender) {
      build(:offender,
            sentence: if indeterminate_sentence
                        build(:sentence_detail,
                              :indeterminate,
                              paroleEligibilityDate: parole_eligibility_date,
                              tariffDate: tariff_date
                        )
                      else
                        build(:sentence_detail,
                              :determinate,
                              automaticReleaseDate: automatic_release_date,
                              conditionalReleaseDate: conditional_release_date,
                              paroleEligibilityDate: parole_eligibility_date
                        )
                      end
            )
    }

    let(:result) do
      described_class.nps_start_date(
        HandoverDateService::OffenderWrapper.new(offender)
      )
    end

    context 'with an indeterminate sentence' do
      let(:indeterminate_sentence) { true }

      context 'with a tariff date' do
        let(:tariff_date) { '1 Jan 2030'.to_date }

        it 'returns 8 months before that date' do
          expect(result).to eq(tariff_date - 8.months)
        end
      end
    end

    context 'with a determinate sentence' do
      let(:determinate_sentence) { false }

      context 'with a parole eligibility date' do
        let(:parole_eligibility_date) { '1 Jan 2020'.to_date }

        it 'returns 8 months before that date' do
          expect(result).to eq(parole_eligibility_date - 8.months)
        end
      end

      context 'without a parole eligibility date' do
        let(:parole_eligibility_date) { nil }

        context 'with only a conditional release date' do
          let(:conditional_release_date) { '1 Jan 2020'.to_date }
          let(:automatic_release_date) { nil }

          it 'returns 7.5 months before that date' do
            expect(result).to eq(conditional_release_date - (7.months + 15.days))
          end
        end

        context 'with only an automatic release date' do
          let(:conditional_release_date) { nil }
          let(:automatic_release_date) { '1 Jan 2020'.to_date }

          it 'returns 7.5 months before that date' do
            expect(result).to eq(automatic_release_date - (7.months + 15.days))
          end
        end

        context 'with both conditional and automatic release dates' do
          let(:conditional_release_date) { '1 Jan 2020'.to_date }
          let(:automatic_release_date) { '1 Feb 2020'.to_date }

          it 'returns 7.5 months before the earliest of the two' do
            expect(result).to eq(conditional_release_date - (7.months + 15.days))
          end
        end

        context 'with no release dates' do
          let(:conditional_release_date) { nil }
          let(:automatic_release_date) { nil }

          it 'returns nil' do
            expect(result).to be_nil
          end
        end
      end
    end
  end

  context 'with an NPS and indeterminate case with a PRD and no TED' do
    let(:case_info) { build(:case_information, :with_prd, :nps) }
    let(:offender) {
      build(:offender, sentence: build(:sentence_detail,
                                       :indeterminate,
                                       tariffDate: nil)).tap {  |offender|
        offender.load_case_information(case_info)
      }
    }

    it 'displays the handover date (which is 8 months prior to PRD) ' do
      expect(described_class.handover(offender).handover_date).to eq(case_info.parole_review_date - 8.months)
    end
  end
end
