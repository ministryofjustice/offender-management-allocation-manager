# frozen_string_literal: true

require 'rails_helper'

describe HandoverDateService do
  subject { described_class.handover(offender) }

  let(:pom) { subject.custody }
  let(:com) { subject.community }
  let(:start_date) { subject.start_date }
  let(:handover_date) { subject.handover_date }
  let(:reason) { subject.reason }

  let(:closed_prison) { 'LEI' } # HMP Leeds
  let(:prescoed_prison) { PrisonService::PRESCOED_CODE } # HMP Prescoed
  let(:open_prison) { 'HVI' } # HMP Haverigg
  let(:prescoed_policy_start_date) { Date.new(2020, 10, 19) } # 19th October 2020
  let(:open_policy_start_date) { Date.new(2021, 3, 31) } # 31st March 2021

  # Set the current date by changing the value of `today`
  let(:today) { Time.zone.today }

  let(:arrival_date) { today }
  let(:welsh?) { false }
  let(:prison) { closed_prison }

  before { Timecop.travel(today) }

  after { Timecop.return }

  context 'when determinate' do
    let(:today) { Date.parse('01/01/2021') }
    let(:crd) { Date.parse('01/09/2022') }
    let(:offender) {
      build(:offender, :determinate,
            latestLocationId: prison,
            sentence: build(:sentence_detail, conditionalReleaseDate: crd)
      ).tap { |o|
        o.load_case_information(case_info)
        o.prison_arrival_date = arrival_date
      }
    }

    context 'when NPS' do
      let(:case_info) { build(:case_information, :nps, welsh_offender: welsh? ? 'Yes' : 'No') }

      it 'handover starts 7.5 months before CRD/ARD' do
        expect(start_date).to eq(crd - (7.months + 15.days))
      end

      it 'handover happens 4.5 months before CRD/ARD' do
        expect(handover_date).to eq(crd - (4.months + 15.days))
      end

      describe 'before handover start date' do
        let(:today) { crd - (7.months + 16.days) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'within the handover window' do
        let(:today) { crd - (7.months + 15.days) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is supporting' do
          expect(com).to be_supporting
        end
      end

      describe 'on/after handover date' do
        let(:today) { crd - (4.months + 15.days) }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering on/after the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 7.5 months before CRD/ARD' do
            expect(start_date).to eq(crd - (7.months + 15.days))
          end

          it 'handover happens 4.5 months before CRD/ARD' do
            expect(handover_date).to eq(crd - (4.months + 15.days))
          end

          describe 'before handover start date' do
            let(:today) { crd - (7.months + 16.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is not needed' do
              expect(com).not_to be_involved
            end
          end

          describe 'within the handover window' do
            let(:today) { crd - (7.months + 15.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { crd - (4.months + 15.days) }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end

        context 'when Welsh offender entering before the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end

        context 'when English offender entering after the policy start date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters on/after the policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts 7.5 months before CRD/ARD' do
            expect(start_date).to eq(crd - (7.months + 15.days))
          end

          it 'handover happens 4.5 months before CRD/ARD' do
            expect(handover_date).to eq(crd - (4.months + 15.days))
          end

          describe 'before handover start date' do
            let(:today) { crd - (7.months + 16.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is not needed' do
              expect(com).not_to be_involved
            end
          end

          describe 'within the handover window' do
            let(:today) { crd - (7.months + 15.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { crd - (4.months + 15.days) }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end

        context 'when offender enters before the policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end
      end
    end

    context 'when CRC' do
      let(:case_info) { build(:case_information, :crc, welsh_offender: welsh? ? 'Yes' : 'No') }

      it 'handover starts 12 weeks before CRD/ARD' do
        expect(start_date).to eq(crd - 12.weeks)
      end

      it 'handover happens 12 weeks before CRD/ARD' do
        expect(handover_date).to eq(crd - 12.weeks)
      end

      describe 'before handover start date' do
        let(:today) { crd - (12.weeks + 1.day) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'on/after handover date' do
        let(:today) { crd - 12.weeks }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering on/after the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when Welsh offender entering before the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when English offender entering after the policy start date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters on/after the policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when offender enters before the policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end
      end
    end
  end

  context 'when indeterminate' do
    context 'with tariff date in the future' do
      let(:tariff_date) { Date.parse('01/09/2022') }
      let(:case_info) { build(:case_information, :nps, welsh_offender: welsh? ? 'Yes' : 'No') }
      let(:offender) {
        build(:offender, :indeterminate,
              latestLocationId: prison,
              sentence: build(:sentence_detail, tariffDate: tariff_date)
        ).tap { |o|
          o.load_case_information(case_info)
          o.prison_arrival_date = arrival_date
        }
      }

      it 'handover starts 8 months before TED/PED/PRD' do
        expect(start_date).to eq(tariff_date - 8.months)
      end

      it 'handover happens 8 months before TED/PED/PRD' do
        expect(handover_date).to eq(tariff_date - 8.months)
      end

      describe 'before handover date' do
        let(:today) { tariff_date - (8.months + 1.day) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'on/after handover date' do
        let(:today) { tariff_date - 8.months }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering before the pilot date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when English offender entering on/after the pilot date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when Welsh offender entering on/after the pilot date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts the day they arrive at the prison' do
            expect(start_date).to eq(offender.prison_arrival_date)
          end

          it 'handover happens 8 months before TED/PED/PRD' do
            expect(handover_date).to eq(tariff_date - 8.months)
          end

          describe 'before handover date' do
            let(:today) { tariff_date - (8.months + 1.day) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { tariff_date - 8.months }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters before the open prison policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when offender enters on/after the open prison policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts the day they arrive at the prison' do
            expect(start_date).to eq(offender.prison_arrival_date)
          end

          it 'handover happens 8 months before TED/PED/PRD' do
            expect(handover_date).to eq(tariff_date - 8.months)
          end

          describe 'before handover date' do
            let(:today) { tariff_date - (8.months + 1.day) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { tariff_date - 8.months }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end
      end
    end
  end
end
