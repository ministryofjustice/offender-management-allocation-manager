RSpec.describe HandoverProgressChecklistsController do
  let(:prison) { FactoryBot.create :prison }
  let(:prison_code) { prison.code }

  before do
    stub_high_level_pom_auth(prison_code: prison_code)
  end

  describe '#edit' do
    describe 'when offender exists' do
      let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
      let(:offender) { instance_double MpcOffender, :offender, offender_no: nomis_offender_id }

      before do
        FactoryBot.create :offender, nomis_offender_id: nomis_offender_id # Internal DB offender, not the MpcOffender
        allow(OffenderService).to receive(:get_offender).and_return nil
      end

      it 'authorizes POM'

      it 'assigns the offender' do
        get :edit, params: {
          prison_id: prison_code,
          nomis_offender_id: nomis_offender_id,
        }

        expect(assigns(:offender)).to eq offender
      end

      it 'assigns existing record if that exists' do
        checklist = FactoryBot.create :handover_progress_checklist, nomis_offender_id: nomis_offender_id
        get :edit, params: {
          prison_id: prison_code,
          nomis_offender_id: checklist.nomis_offender_id,
        }

        aggregate_failures do
          expect(response.code).to eq '200'
          expect(assigns(:handover_progress_checklist)).to eq checklist
        end
      end

      it 'assigns new record if one does not already exist' do
        get :edit, params: {
          prison_id: prison_code,
          nomis_offender_id: nomis_offender_id,
        }

        record = assigns(:handover_progress_checklist)
        aggregate_failures do
          expect(response.code).to eq '200'
          expect(record.new_record?).to eq true
          expect(record.nomis_offender_id).to eq nomis_offender_id
        end
      end
    end

    describe 'when offender does not exist' do
      it 'shows error'
    end
  end
end
