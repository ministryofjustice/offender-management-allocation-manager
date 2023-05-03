RSpec.describe Api::OffendersController, type: :controller do
  let(:nomis_offender_id) { 'X1111XX' }

  before do
    allow(OffenderService).to receive(:get_offender)
  end

  it 'requires authentication' do
    get :show, params: {  nomis_offender_id: nomis_offender_id }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'when authenticated' do
    let(:mock_mpc_offender) do
      instance_double MpcOffender, offender_no: nomis_offender_id, early_allocation?: true
    end

    before do
      allow(controller).to receive(:verify_token)
    end

    it 'has a valid response when offender exists' do
      allow(OffenderService).to receive(:get_offender).with(nomis_offender_id).and_return(mock_mpc_offender)
      get :show, params: { nomis_offender_id: nomis_offender_id }, format: :json
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(ActiveSupport::JSON.decode(response.body)).to eq({
          'offender_no' => nomis_offender_id,
          'noms_number' => nomis_offender_id,
          'early_allocation_eligibility_status' => true,
        })
      end
    end

    it 'responds with 404 when offender does not exist' do
      get :show, params: { nomis_offender_id: nomis_offender_id }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
