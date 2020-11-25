# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessDeliusDataJob, :disable_push_to_delius,
               vcr: { cassette_name: :process_delius_job }, type: :job do
  let(:nomis_offender_id) { 'G4281GV' }
  let(:remand_nomis_offender_id) { 'G3716UD' }
  let(:ldu) {  create(:local_divisional_unit) }
  let(:team) { create(:team, local_divisional_unit: ldu) }

  context 'with auto_delius_import enabled' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      test_strategy.switch!(:auto_delius_import, true)
    end

    after do
      test_strategy.switch!(:auto_delius_import, false)
    end

    context 'when duplicate NOMIS ids exist' do
      let!(:d1) {
        create(:delius_data, noms_no: nomis_offender_id, team_code: team.code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }
      let!(:d2) {
        create(:delius_data, noms_no: nomis_offender_id, team_code: team.code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'flags up the duplicate IDs' do
        expect {
          expect {
            described_class.perform_now nomis_offender_id
          }.not_to change(CaseInformation, :count)
        }.to change(DeliusImportError, :count).by(1)

        expect(DeliusImportError.last(2).map(&:nomis_offender_id)).to match_array [nomis_offender_id]
        expect(DeliusImportError.last(2).map(&:error_type)).to match_array [DeliusImportError::DUPLICATE_NOMIS_ID]
      end
    end

    context 'when on the happy path' do
      let!(:d1) {
        create(:delius_data, team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(1)
      end
    end

    context 'when processing a com name' do
      let(:offender_id) { 'A1111A' }
      let!(:d1) {
        create(:delius_data, offender_manager: com_name, team_code: team.shadow_code, team: team.name,
               ldu_code: ldu.code, ldu: ldu.name)
      }

      context 'with a normal COM name' do
        let(:com_name) { 'Bob Smith' }

        it 'shows com name' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)

          expect(CaseInformation.last.com_name).to eq(com_name)
        end
      end

      context 'with an unallocated com name' do
        let(:com_name) { 'Staff, Unallocated' }

        it 'maps com_name to nil' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)

          expect(CaseInformation.last.com_name).to be_nil
        end
      end

      context 'with an inactive com name' do
        let(:com_name) { 'Staff, Inactive Staff(N07)' }

        it 'maps com_name to nil' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)

          expect(CaseInformation.last.com_name).to be_nil
        end
      end
    end

    context 'when offender is not convicted' do
      let!(:d1) {
        create(:delius_data, noms_no: remand_nomis_offender_id, team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'does not case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(0)
      end
    end

    context 'when tier contains extra characters' do
      let!(:d1) {
        create(:delius_data, tier: 'B1', team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(1)
        expect(CaseInformation.last.tier).to eq('B')
      end
    end

    context 'when tier is invalid' do
      let!(:d1) {
        create(:delius_data, tier: 'X', team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'does not creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
      end
    end

    describe '#welsh_offender' do
      let(:case_info) { CaseInformation.last }
      let(:delius_record) { create(:delius_data, ldu_code: ldu.code, team_code: team.code) }

      context 'with an English LDU' do
        let(:ldu) { create(:local_divisional_unit, in_wales: false) }

        it 'maps to false' do
          described_class.perform_now(delius_record.noms_no)
          expect(case_info.welsh_offender).to eq('No')
        end
      end

      context 'with an Welsh LDU' do
        let(:ldu) { create(:local_divisional_unit, in_wales: true) }

        it 'maps to true' do
          described_class.perform_now(delius_record.noms_no)
          expect(case_info.welsh_offender).to eq('Yes')
        end
      end
    end

    describe '#mappa' do
      context 'without delius mappa' do
        let!(:d1) {
          create(:delius_data, mappa: 'N', team_code: team.shadow_code, team: team.name,
                               ldu_code: ldu.code, ldu: ldu.name)
        }

        it 'creates case information with mappa level 0' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
          expect(CaseInformation.last.mappa_level).to eq(0)
        end
      end

      context 'with delius mappa' do
        let!(:d1) {
          create(:delius_data, mappa: 'Y', mappa_levels: mappa_levels, team_code: team.shadow_code, team: team.name,
                               ldu_code: ldu.code, ldu: ldu.name)
        }

        context 'with delius mappa data is 1' do
          let(:mappa_levels) { '1' }

          it 'creates case information with mappa level 1' do
            expect {
              described_class.perform_now d1.noms_no
            }.to change(CaseInformation, :count).by(1)
            expect(CaseInformation.last.mappa_level).to eq(1)
          end
        end

        context 'with delius mappa data is 1,2' do
          let(:mappa_levels) { '1,2' }

          it 'creates case information with mappa level 2' do
            expect {
              described_class.perform_now d1.noms_no
            }.to change(CaseInformation, :count).by(1)
            expect(CaseInformation.last.mappa_level).to eq(2)
          end
        end

        context 'with delius mappa data is 1,Nominal' do
          let(:mappa_levels) { '1,Nominal' }

          it 'creates case information with mappa level 1' do
            expect {
              described_class.perform_now d1.noms_no
            }.to change(CaseInformation, :count).by(1)
            expect(CaseInformation.last.mappa_level).to eq(1)
          end
        end
      end
    end

    context 'when tier is missing' do
      let!(:d1) {
        create(:delius_data, tier: nil, team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'does not creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
      end
    end

    context 'when invalid service provider' do
      let!(:d1) {
        create(:delius_data, provider_code: 'X123', team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'does not creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
      end
    end

    context 'when date contains 8 stars' do
      let!(:d1) {
        create(:delius_data, date_of_birth: '*' * 8, team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'creates a new case information record' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(1)
      end
    end

    context 'when date invalid' do
      let!(:d1) {
        create(:delius_data, date_of_birth: 'ohdearieme', team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }

      it 'creates an error record' do
        expect {
          expect {
            described_class.perform_now d1.noms_no
          }.not_to change(CaseInformation, :count)
        }.to change(DeliusImportError, :count).by(1)

        expect(DeliusImportError.last.error_type).to eq(DeliusImportError::MISMATCHED_DOB)
      end
    end

    context 'when case information already present' do
      let!(:d1) {
        create(:delius_data, tier: 'C', team_code: team.shadow_code, team: team.name,
                             ldu_code: ldu.code, ldu: ldu.name)
      }
      let!(:c1) { create(:case_information, tier: 'B', nomis_offender_id: d1.noms_no, crn: d1.crn) }

      it 'does not creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
        expect(c1.reload.tier).to eq('C')
      end
    end

    describe 'pushing handover dates into nDelius' do
      let!(:delius_data) {
        create(:delius_data, tier: 'C', team_code: team.shadow_code, team: team.name,
               ldu_code: ldu.code, ldu: ldu.name, provider_code: 'NPS')
      }

      let(:offender) { OffenderService.get_offender(delius_data.noms_no) }

      shared_examples 'recalculate handover dates' do
        it "recalculates the offender's handover dates, using the new Case Information data" do
          expect(CalculatedHandoverDate).to receive(:recalculate_for) do |received_offender|
            expect(received_offender).to be_an_instance_of(HmppsApi::Offender)

            expected_fields = {
              crn: delius_data.crn,
              tier: 'C',
              case_allocation: 'NPS',
              welsh_offender: false,
              mappa_level: 0
            }

            received_fields = {
              crn: received_offender.crn,
              tier: received_offender.tier,
              case_allocation: received_offender.case_allocation,
              welsh_offender: received_offender.welsh_offender,
              mappa_level: received_offender.mappa_level
            }

            expect(received_fields).to eq(expected_fields)
          end
          described_class.perform_now delius_data.noms_no
        end
      end

      context 'when creating a new Case Information record' do
        include_examples 'recalculate handover dates'
      end

      context 'when updating an existing Case Information record' do
        let!(:case_info) {
          create(:case_information, tier: 'B', nomis_offender_id: delius_data.noms_no, crn: delius_data.crn)
        }

        include_examples 'recalculate handover dates'
      end

      context 'when there were errors saving the record' do
        before do
          delius_data.update(team_code: 'Bad team code')
        end

        it 'does not recalculate handover dates' do
          expect(CalculatedHandoverDate).not_to receive(:recalculate_for)
          described_class.perform_now delius_data.noms_no
        end
      end
    end
  end

  context 'without auto_delius_import enabled' do
    context 'with one prison enabled' do
      before do
        ENV['AUTO_DELIUS_IMPORT'] = 'VEN,LEI,HGT'
      end

      context 'when on the happy path' do
        let!(:d1) {
          create(:delius_data, team_code: team.shadow_code, team: team.name,
                               ldu_code: ldu.code, ldu: ldu.name)
        }

        it 'creates case information' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
        end
      end
    end

    context 'with non-enabled prison' do
      before do
        ENV['AUTO_DELIUS_IMPORT'] = 'RSI,VEN'
      end

      context 'when on the happy path' do
        let!(:d1) {
          create(:delius_data, team_code: team.shadow_code, team: team.name,
                               ldu_code: ldu.code, ldu: ldu.name)
        }

        it 'creates case information' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
        end
      end
    end
  end
end
