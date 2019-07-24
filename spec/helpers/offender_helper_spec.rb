require 'rails_helper'

RSpec.describe OffenderHelper do
  describe 'Digital Prison Services profile path' do
    it "formats the link to an offender's profile page within the Digital Prison Services" do
      expect(digital_prison_service_profile_path('AB1234A')).to eq("#{Rails.configuration.digital_prison_service_host}/offenders/AB1234A/quick-look")
    end
  end

  describe 'handovers' do
    let(:determinate_status) { 'CRIM_CON' }
    let(:indeterminate_status) { 'LIFE' }

    describe '#handover_start_date' do
      context 'when NPS' do
        context 'with early allocation' do
          let(:offender) { OpenStruct.new(nps_case?: true, early_allocation?: true) }

          it 'is not set' do
            expect(helper.handover_start_date(offender)[0]).to be_nil
          end
        end

        context 'with normal allocation' do
          let(:release_date) { Date.new(2020, 8, 30) }

          let(:offender) { OpenStruct.new(imprisonment_status: status, nps_case?: true, earliest_release_date: release_date) }

          context 'with determinate sentence' do
            let(:status) { determinate_status }

            it 'is 7.5 months before release date' do
              expect(helper.handover_start_date(offender)[0]).to eq(Date.new(2020, 1, 15))
            end
          end

          context "with indeterminate sentence" do
            let(:status) { indeterminate_status }

            it 'is 8 months before release date' do
              expect(helper.handover_start_date(offender)[0]).to eq(Date.new(2019, 12, 30))
            end
          end
        end
      end

      context 'when CRC' do
        let(:offender) { OpenStruct.new(nps_case?: false) }

        it 'is not set' do
          expect(helper.handover_start_date(offender)[0]).to be_nil
        end
      end
    end

    describe '#responsibility_handover_date' do
      context 'when CRC' do
        stub_const("CRCHandoverData", Struct.new(:nps_case?, :home_detention_curfew_eligibility_date, :conditional_release_date, :result))

        stub_const("CRC_CASES", [
          CRCHandoverData.new(false, Date.new(2019, 9, 30), Date.new(2019, 8, 1), Date.new(2019, 5, 9)), # 12 weeks before CRD
          CRCHandoverData.new(false, Date.new(2019, 8, 1), Date.new(2019, 8, 12), Date.new(2019, 5, 9)), # 12 weeks before HDC date
          CRCHandoverData.new(false, nil, Date.new(2019, 8, 1), Date.new(2019, 5, 9)), # 12 weeks before CRD date
          CRCHandoverData.new(false, Date.new(2019, 8, 1), nil, Date.new(2019, 5, 9)), # 12 weeks before HDC date
          CRCHandoverData.new(false, nil, nil, nil) # no handover date
        ])

        context 'with tablular data source' do
          it 'returns the specified result' do
            CRC_CASES.each do |data|
              expect(helper.responsibility_handover_date(data)[0]).to eq(data.result)
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
                           automatic_release_date: ard)
          }

          context 'when CRD earliest' do
            let(:ard) { Date.new(2019, 8, 1) }
            let(:crd) { Date.new(2019, 7, 1) }

            it 'is 15 months before CRD' do
              expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2018, 4, 1))
            end
          end

          context 'when ARD earliest' do
            let(:ard) { Date.new(2019, 8, 1) }
            let(:crd) { Date.new(2019, 9, 30) }

            it 'is 15 months before ARD' do
              expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2018, 5, 1))
            end
          end

          context 'with neither date' do
            let(:crd) { nil }
            let(:ard) { nil }

            it 'cannot be calculated' do
              expect(helper.responsibility_handover_date(offender)[0]).to be_nil
            end
          end
        end

        context 'with normal allocation' do
          let(:parole_date) { nil }
          let(:crd) { Date.new(2020, 7, 16) }
          let(:hdc_date) { Date.new(2020, 6, 16) }

          context 'with determinate sentence' do
            let(:mappa_level) { nil }

            let(:offender) {
              OpenStruct.new(imprisonment_status: determinate_status,
                             nps_case?: true,
                             mappa_level: mappa_level,
                             home_detention_curfew_eligibility_date: hdc_date,
                             conditional_release_date: crd,
                             automatic_release_date: Date.new(2020, 8, 16),
                             parole_eligibility_date: parole_date,
                             tariff_date: Date.new(2020, 11, 1))
            }

            context 'with parole date' do
              let(:parole_date) { Date.new(2019, 9, 30) }

              it 'is 8 months before parole date' do
                expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2019, 1, 30))
              end
            end

            context 'when non-parole case' do
              context 'without mappa' do
                context 'when crd before ard' do
                  it 'is 4.5 months before CRD' do
                    expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 3, 1))
                  end
                end

                context 'when crd after ard' do
                  let(:crd) { Date.new(2020, 8, 17) }

                  it 'is 4.5 months before ARD' do
                    expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 4, 1))
                  end
                end

                context 'when HDC date earlier than date indicated by CRD/ARD' do
                  let(:hdc_date) { Date.new(2020, 2, 28) }

                  it 'is on HDC date' do
                    expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 2, 28))
                  end
                end
              end

              context 'with mappa level 1' do
                let(:mappa_level) { 1 }

                it 'is 4.5 months before CRD/ARD date or on HDC date' do
                  expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 3, 1))
                end
              end

              context 'with mappa level 2' do
                let(:mappa_level) { 2 }

                it 'is 7.5 months before CRD/ARD date' do
                  expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2019, 12, 1))
                end
              end

              context 'with mappa level 3' do
                let(:mappa_level) { 3 }

                it 'is 7.5 months before CRD/ARD date' do
                  expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2019, 12, 1))
                end
              end
            end
          end

          context "with indeterminate sentence" do
            let(:offender) {
              OpenStruct.new(imprisonment_status: indeterminate_status,
                             nps_case?: true,
                             parole_eligibility_date: parole_date,
                             tariff_date: tariff_date)
            }

            context 'with tariff date earliest' do
              let(:tariff_date) { Date.new(2020, 11, 1) }
              let(:parole_date) { Date.new(2020, 12, 1) }

              it 'is 8 months before tariff date' do
                expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 3, 1))
              end
            end

            context 'with parole_eligibility_date earliest' do
              let(:parole_date) { Date.new(2020, 10, 1) }
              let(:tariff_date) { Date.new(2020, 11, 1) }

              it 'is 8 months before parole date' do
                expect(helper.responsibility_handover_date(offender)[0]).to eq(Date.new(2020, 2, 1))
              end
            end

            context 'with neither date' do
              let(:parole_date) { nil }
              let(:tariff_date) { nil }

              it 'cannot be calculated' do
                expect(helper.responsibility_handover_date(offender)[0]).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
