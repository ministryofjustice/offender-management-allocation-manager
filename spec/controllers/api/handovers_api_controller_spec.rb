RSpec.describe Api::HandoversApiController, type: :controller do
  let(:nomis_offender_id) { 'X1111XX' }

  it 'requires authentication' do
    get :show, params: { id: nomis_offender_id }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'when authenticated' do
    before do
      allow(controller).to receive(:verify_token)
      allow(Api::Handover).to receive(:[])
    end

    describe 'GET /' do
      let(:handover) do
        instance_double Api::Handover,
                        as_json: { 'noms_number' => nomis_offender_id,
                                   'handover_start_date' => Date.new(2024, 6, 1),
                                   'handover_date' => Date.new(2024, 7, 1),
                                   'responsibility' => 'POM' }
      end

      it 'gets a valid handover' do
        allow(Api::Handover).to receive(:[]).with(nomis_offender_id).and_return(handover)
        get :show, params: { id: nomis_offender_id }, format: :json

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(ActiveSupport::JSON.decode(response.body)).to eq({
            'noms_number' => nomis_offender_id,
            'handover_start_date' => '2024-06-01',
            'handover_date' => '2024-07-01',
            'responsibility' => 'POM',
          })
        end
      end

      it 'responds with 404 if no handover' do
        get :show, params: { id: nomis_offender_id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
