require 'rails_helper'

describe HandoverDateService do
  describe '#handover_start_date' do
    context 'when NPS' do
      context 'with early allocation' do
        let(:offender) { OpenStruct.new(nps_case?: true, early_allocation?: true) }

        it 'is not set' do
          expect(described_class.handover(offender).start_date).to be_nil
        end
      end

      context 'with normal allocation' do
        let(:release_date) { Date.new(2020, 8, 30) }
        # TODO: This is an interim measure as we have not yet amended the HandoverDateService code
        let(:offender) { OpenStruct.new(indeterminate_sentence?: indeterminate, nps_case?: true, automatic_release_date: release_date, tariff_date: release_date) }

        context 'with determinate sentence' do
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
        end
      end
    end

    context 'when CRC' do
      let(:offender) { OpenStruct.new(nps_case?: false) }

      it 'is not set' do
        expect(described_class.handover(offender).start_date).to be_nil
      end
    end
  end

  describe '#responsibility_handover_date' do
    context 'when CRC' do
      before do
        stub_const("CRCHandoverData", Struct.new(:recalled?, :nps_case?, :home_detention_curfew_eligibility_date, :conditional_release_date, :earliest_release_date, :result))

        stub_const("CRC_CASES", [
            CRCHandoverData.new(false, false, Date.new(2019, 9, 30), Date.new(2019, 8, 1), Date.new(2019, 8, 1), Date.new(2019, 5, 9)), # 12 weeks before CRD
            CRCHandoverData.new(false, false, Date.new(2019, 8, 1), Date.new(2019, 8, 12), Date.new(2019, 8, 1), Date.new(2019, 5, 9)), # 12 weeks before HDC date
            CRCHandoverData.new(false, false, nil, Date.new(2019, 8, 1), Date.new(2019, 5, 9), Date.new(2019, 5, 9)), # 12 weeks before CRD date
            CRCHandoverData.new(false, false, Date.new(2019, 8, 1), nil, Date.new(2019, 8, 1), Date.new(2019, 5, 9)), # 12 weeks before HDC date
            CRCHandoverData.new(false, false, nil, nil, nil, nil) # no handover date
        ])
      end

      context 'with tablular data source' do
        it 'returns the specified result' do
          CRC_CASES.each do |data|
            expect(described_class.handover(data).handover_date).to eq(data.result)
          end
        end
      end
    end

    context 'when NPS' do
      context 'with early_allocation' do
        let(:offender) {
          OpenStruct.new(nps_case?: true,
                         early_allocation?: true,
                         conditional_release_date: crd,
                         automatic_release_date: ard,
                         earliest_release_date: erd)
        }

        context 'when CRD earliest' do
          let(:ard) { Date.new(2019, 8, 1) }
          let(:crd) { Date.new(2019, 7, 1) }
          let(:erd) { Date.new(2019, 7, 1) }

          it 'is 15 months before CRD' do
            expect(described_class.handover(offender).handover_date).to eq(Date.new(2018, 4, 1))
          end
        end

        context 'when ARD earliest' do
          let(:ard) { Date.new(2019, 8, 1) }
          let(:crd) { Date.new(2019, 9, 30) }
          let(:erd) { Date.new(2019, 8, 1) }

          it 'is 15 months before ARD' do
            expect(described_class.handover(offender).handover_date).to eq(Date.new(2018, 5, 1))
          end
        end

        context 'with neither date' do
          let(:crd) { nil }
          let(:ard) { nil }
          let(:erd) { nil }

          it 'cannot be calculated' do
            expect(described_class.handover(offender).handover_date).to be_nil
          end
        end
      end

      context 'with normal allocation' do
        let(:parole_date) { nil }
        let(:crd) { Date.new(2020, 7, 16) }
        let(:hdc_date) { Date.new(2020, 6, 16) }
        let(:erd) { Date.new(2020, 6, 16) }

        context 'with determinate sentence' do
          let(:mappa_level) { nil }

          let(:offender) {
            OpenStruct.new(inderminate_sentence?: false,
                           nps_case?: true,
                           mappa_level: mappa_level,
                           home_detention_curfew_eligibility_date: hdc_date,
                           conditional_release_date: crd,
                           automatic_release_date: Date.new(2020, 8, 16),
                           parole_eligibility_date: parole_date,
                           tariff_date: Date.new(2020, 11, 1),
                           earliest_release_date: Date.new(2020, 8, 16))
          }

          context 'with parole date' do
            let(:parole_date) { Date.new(2019, 9, 30) }
            let(:erd) { Date.new(2019, 9, 30) }

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
                let(:hdc_date) { Date.new(2020, 2, 28) }

                it 'is on HDC date' do
                  expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 2, 28))
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

              it 'is 7.5 months before CRD/ARD date' do
                expect(described_class.handover(offender).handover_date).to eq(Date.new(2019, 12, 1))
              end
            end

            context 'with mappa level 3' do
              let(:mappa_level) { 3 }

              it 'is 7.5 months before CRD/ARD date' do
                expect(described_class.handover(offender).handover_date).to eq(Date.new(2019, 12, 1))
              end
            end
          end
        end

        context "with indeterminate sentence" do
          let(:offender) {
            OpenStruct.new(indeterminate_sentence?: true,
                           nps_case?: true,
                           parole_eligibility_date: parole_date,
                           tariff_date: tariff_date,
                           earliest_release_date: erd)
          }

          context 'with tariff date earliest' do
            let(:tariff_date) { Date.new(2020, 11, 1) }
            let(:parole_date) { Date.new(2020, 12, 1) }
            let(:erd) { Date.new(2020, 11, 1) }

            it 'is 8 months before tariff date' do
              expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 3, 1))
            end
          end

          context 'with parole_eligibility_date earliest' do
            let(:parole_date) { Date.new(2020, 10, 1) }
            let(:tariff_date) { Date.new(2020, 11, 1) }
            let(:erd) { Date.new(2020, 10, 1) }

            it 'is 8 months before parole date' do
              expect(described_class.handover(offender).handover_date).to eq(Date.new(2020, 2, 1))
            end
          end

          context 'with neither date' do
            let(:parole_date) { nil }
            let(:tariff_date) { nil }
            let(:erd) { nil }

            it 'cannot be calculated' do
              expect(described_class.handover(offender).handover_date).to be_nil
            end
          end
        end
      end
    end
  end
end
