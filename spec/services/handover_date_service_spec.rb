require 'rails_helper'

describe HandoverDateService do
  describe '#handover_start_date' do
    context 'when NPS' do
      let(:offender) {
        OpenStruct.new indeterminate_sentence?: indeterminate,
                       nps_case?: true,
                       automatic_release_date: release_date,
                       tariff_date: tariff_date
      }

      let(:release_date) { Date.new(2020, 8, 30) }
      let(:tariff_date) { release_date }

      context 'with a determinate sentence' do
        let(:indeterminate) { false }

        it 'is 7.5 months before release date' do
          expect(described_class.handover(offender).start_date).to eq(Date.new(2020, 1, 15))
        end
      end

      context "with indeterminate sentence" do
        let(:indeterminate) { true }

        it 'is 8 months before release date' do
          expect(described_class.handover(offender).start_date).to eq(Date.new(2019, 12, 30))
        end

        context 'with no tariff date' do
          let(:tariff_date) { nil }

          it 'is not set' do
            expect(described_class.handover(offender).start_date).to be_nil
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
        OpenStruct.new indeterminate_sentence?: true,
                       nps_case?: false,
                       tariff_date: tariff_date
      }

      let(:release_date) { Date.new(2020, 8, 30) }
      let(:tariff_date) { release_date }

      it 'is 8 months before release date' do
        expect(described_class.handover(offender).start_date).to eq(Date.new(2019, 12, 30))
      end
    end

    context 'with early allocation' do
      let(:offender) { OpenStruct.new(nps_case?: true, early_allocation?: true, conditional_release_date: Date.new(2021, 6, 2)) }

      it 'will be 18 months before CRD' do
        expect(described_class.handover(offender).start_date).to eq(Date.new(2019, 12, 2))
      end
    end
  end

  describe '#responsibility_handover_date' do
    context 'when CRC' do
      let(:offender) {
        OpenStruct.new  recalled?: false,
                        nps_case?: false,
                        automatic_release_date: ard,
                        conditional_release_date: crd,
                        home_detention_curfew_actual_date: hdcad,
                        home_detention_curfew_eligibility_date: hdced
      }

      context 'when 12 weeks before the CRD date' do
        let(:ard)   { Date.new(2019, 8, 1) }
        let(:crd)   { Date.new(2019, 8, 12) }
        let(:hdcad) { nil }
        let(:hdced) { nil }

        it 'will return the handover date 12 weeks before the CRD' do
          expect(described_class.handover(offender).handover_date).to eq Date.new(2019, 5, 9)
        end
      end

      context 'when 12 weeks before the ARD date' do
        let(:ard)   { Date.new(2019, 8, 12) }
        let(:crd)   { Date.new(2019, 8, 1) }
        let(:hdcad) { nil }
        let(:hdced) { nil }

        it 'will return the handover date 12 weeks before the ARD' do
          expect(described_class.handover(offender).handover_date).to eq Date.new(2019, 5, 9)
        end
      end

      context 'when HDCED date is present' do
        let(:ard)   { Date.new(2019, 8, 1) }
        let(:crd)   { Date.new(2019, 8, 12) }
        let(:hdcad) { nil }
        let(:hdced) { Date.new(2019, 7, 25) }

        it 'the handover date will be on the HDCED date' do
          expect(described_class.handover(offender).handover_date).to eq Date.new(2019, 7, 25)
        end
      end

      context 'when HDCAD date is present' do
        let(:ard)   { Date.new(2019, 8, 1) }
        let(:crd)   { Date.new(2019, 8, 12) }
        let(:hdcad) { Date.new(2019, 7, 26) }
        let(:hdced) { Date.new(2019, 7, 25) }

        it 'the handover date will be on the HDCAD date' do
          expect(described_class.handover(offender).handover_date).to eq Date.new(2019, 7, 26)
        end
      end

      context 'when there are no release related dates' do
        let(:ard)   { nil }
        let(:crd)   { nil }
        let(:hdcad) { nil }
        let(:hdced) { nil }

        it 'will return no handover date' do
          expect(described_class.handover(offender).handover_date).to eq nil
        end
      end
    end

    context 'when NPS' do
      context 'with normal allocation' do
        let(:parole_date) { nil }
        let(:ted)         { Date.new(2020, 11, 1) }
        let(:crd)         { Date.new(2020, 7, 16) }
        let(:ard)         { Date.new(2020, 8, 16) }
        let(:hdced_date)  { nil }
        let(:hdcad_date)  { nil }

        context 'with determinate sentence' do
          let(:mappa_level) { nil }

          let(:offender) {
            OpenStruct.new(inderminate_sentence?: false,
                           nps_case?: true,
                           mappa_level: mappa_level,
                           home_detention_curfew_eligibility_date: hdced_date,
                           conditional_release_date: crd,
                           automatic_release_date: ard,
                           parole_eligibility_date: parole_date,
                           tariff_date: ted,
                           home_detention_curfew_actual_date: hdcad_date)
          }

          context 'with parole eligibility' do
            let(:parole_date) { Date.new(2019, 9, 30) }

            it 'is 8 months before parole date' do
              expect(described_class.handover(offender).handover_date).to eq(Date.new(2019, 1, 30))
            end
          end

          context 'when non-parole case' do
            context 'when mappa unknown' do
              let(:mappa_level) { nil }

              context 'when crd before ard' do
                it 'is 4.5 months before CRD' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 3, 1))
                end
              end

              context 'when HDCED is present' do
                let(:hdced_date) {  Date.new(2020, 6, 16) }

                it 'is set to HDCED' do
                  expect(described_class.handover(offender).handover_date).to eq(hdced_date)
                end
              end

              context 'when HDCAD is present' do
                let(:hdced_date) { Date.new(2020, 6, 16) }
                let(:hdcad_date) { Date.new(2020, 6, 20) }

                it 'is set to HDCAD' do
                  expect(described_class.handover(offender).handover_date).to eq(hdcad_date)
                end
              end
            end

            context 'without mappa' do
              # mappa level 0 means MAAPA doesn't apply
              let(:mappa_level) { 0 }

              context 'when crd before ard' do
                it 'is 4.5 months before CRD' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 3, 1))
                end
              end

              context 'when crd after ard' do
                let(:crd) { Date.new(2020, 8, 17) }

                it 'is 4.5 months before ARD' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 4, 1))
                end
              end

              context 'when HDC date earlier than date indicated by CRD/ARD' do
                let(:hdced_date) { Date.new(2020, 2, 28) }

                it 'is on HDC date' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 2, 28))
                end
              end

              context 'when HDCAD is present' do
                let(:hdcad_date) { Date.new(2020, 2, 15) }
                let(:hdced_date) { Date.new(2020, 2, 28) }

                it 'is on HDCAD date' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 2, 15))
                end
              end
            end

            context 'with mappa level 1' do
              let(:mappa_level) { 1 }

              it 'is 4.5 months before CRD/ARD date or on HDC date' do
                expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 3, 1))
              end
            end

            context 'with mappa level 2' do
              let(:mappa_level) { 2 }

              it 'is todays date' do
                expect(described_class.handover(offender).handover_date).to eq(Time.zone.today)
              end
            end

            context 'with mappa level 3' do
              let(:mappa_level) { 3 }

              it 'is todays date' do
                expect(described_class.handover(offender).handover_date).to eq(Time.zone.today)
              end
            end
          end
        end

        context "with indeterminate sentence" do
          let(:offender) {
            OpenStruct.new(indeterminate_sentence?: true,
                           nps_case?: true,
                           tariff_date: tariff_date)
          }

          context 'with tariff date in the future' do
            let(:tariff_date) { Date.new(2020, 11, 1) }

            it 'is 8 months before tariff date' do
              expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 3, 1))
            end
          end

          context 'with neither date' do
            let(:tariff_date) { nil }

            it 'cannot be calculated' do
              expect(described_class.handover(offender).handover_date).to be_nil
            end
          end
        end
      end

      context 'with early_allocation' do
        let(:offender) {
          OpenStruct.new(nps_case?: true,
                         early_allocation?: true,
                         conditional_release_date: crd)
        }

        context 'when CRD earliest' do
          let(:crd) { Date.new(2019, 7, 1) }

          it 'is 15 months before CRD' do
            expect(described_class.handover(offender).handover_date).to eq(Date.new(2018, 4, 1))
          end
        end
      end
    end
  end

  describe '#nps_start_date' do
    let(:early_allocation) { false }
    let(:indeterminate_sentence) { false }
    let(:conditional_release_date) { nil }
    let(:parole_eligibility_date) { nil }
    let(:tariff_date) { nil }
    let(:automatic_release_date) { nil }

    let(:result) do
      described_class.nps_start_date(
        double(
          automatic_release_date: automatic_release_date,
          conditional_release_date: conditional_release_date,
          "early_allocation?" => early_allocation,
          "indeterminate_sentence?" => indeterminate_sentence,
          parole_eligibility_date: parole_eligibility_date,
          tariff_date: tariff_date
        )
      )
    end

    context 'when the case is early allocation' do
      let(:early_allocation) { true }

      context 'with a conditional release date' do
        let(:conditional_release_date) { '1 Jan 2020'.to_date }

        it 'returns 18 months before that date' do
          expect(result).to eq(conditional_release_date - 18.months)
        end
      end

      context 'without a conditional release date' do
        it 'returns nil' do
          expect(result).to be_nil
        end
      end
    end

    context 'with an indeterminate sentence' do
      let(:indeterminate_sentence) { true }

      context 'with a tariff date' do
        let(:tariff_date) { '1 Jan 2020'.to_date }

        it 'returns 8 months before that date' do
          expect(result).to eq(tariff_date - 8.months)
        end
      end

      context 'without a tariff date' do
        it 'returns nil' do
          expect(result).to be_nil
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
end
