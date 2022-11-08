RSpec.describe HandoverProgressChecklistsController do
  let(:prison) { FactoryBot.create :prison }
  let(:prison_code) { prison.code }

  before do
    stub_high_level_pom_auth(prison_code: prison_code)
  end

  describe '#edit' do
    it 'assigns existing record if that exists' do
      checklist = FactoryBot.create :handover_progress_checklist
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
      nomis_offender_id = FactoryBot.generate(:nomis_offender_id)
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
end
