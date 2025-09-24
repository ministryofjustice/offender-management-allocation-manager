RSpec.describe ComplexityLevelsController, type: :controller do
  let(:offender) { build(:nomis_offender, complexityLevel: 'medium', prisonId: womens_prison.code, firstName: 'Sally', lastName: 'Albright') }
  let(:womens_prison) { create(:womens_prison) }
  let(:offenders) { [offender] }
  let(:pom) { build(:pom) }
  let(:spo) { build(:pom) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: womens_prison.code)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))

    stub_offenders_for_prison(womens_prison.code, offenders)
    stub_sso_data(womens_prison.code)
    stub_poms(womens_prison.code, [pom, spo])
    stub_keyworker(offender_no)
  end

  describe '#edit' do
    it 'displays an edit page' do
      get :edit,  params: { prison_id: womens_prison.code, prisoner_id: offender_no }
      expect(response).to be_successful
      expect(assigns(:complexity).level).to eq('medium')
    end
  end

  describe '#update' do
    before do
      allow(HmppsApi::ComplexityApi).to receive(:save)
    end

    context 'when complexity level increases from medium to high' do
      let(:updated_complexity_level) { 'high' }

      it 'saves the complexity level and renders the renders the confirmation page' do
        post :update,  params: { complexity: { level: updated_complexity_level, reason: 'Just because' }, prison_id: womens_prison.code, prisoner_id: offender_no }
        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(assigns(:previous_complexity_level)).to eq('medium')
          expect(assigns(:complexity).level).to eq('high')
          expect(assigns(:offender_id)).to eq(offender_no)
          expect(assigns(:prisoner).first_name).to eq('Sally')
          expect(assigns(:prisoner).last_name).to eq('Albright')

          expect(HmppsApi::ComplexityApi).to have_received(:save).with(
            offender_no,
            level: updated_complexity_level,
            username: 'user',
            reason: 'Just because'
          )
        end
      end
    end

    context 'when complexity level remains the same' do
      let(:updated_complexity_level) { 'medium' }

      it 'saves the complexity level and redirects to the prisoner profile page' do
        post :update,  params: { complexity: { level: 'medium', reason: 'Just because' }, prison_id: womens_prison.code, prisoner_id: offender_no }
        expect(response).to redirect_to(prison_prisoner_allocation_path(womens_prison.code, offender_no))
      end
    end
  end
end
