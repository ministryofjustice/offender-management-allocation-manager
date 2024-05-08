RSpec.describe Api::HandoversApiController, type: :controller do
  let(:nomis_offender_id) { 'GA345AB' }

  it 'requires authentication' do
    get :show, params: { id: nomis_offender_id }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'when authenticated' do
    before { allow(controller).to receive(:verify_token) }

    describe 'GET /' do
      context "when no handover exists for offende" do
        it 'responds with 404' do
          get :show, params: { id: nomis_offender_id }, format: :json
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the handover exists" do
        it "returns the handover in json form" do
          create(
            :calculated_handover_date,
            offender: build(:offender, nomis_offender_id:),
            start_date: Date.new(2024, 6, 1),
            handover_date: Date.new(2024, 7, 1),
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
          )

          get :show, params: { id: nomis_offender_id }, format: :json

          expect(JSON.parse(response.body)).to eq(
            'nomsNumber' => nomis_offender_id,
            'handoverStartDate' => '2024-06-01',
            'handoverDate' => '2024-07-01',
            'responsibility' => 'COM',
          )
        end
      end
    end
  end
end
