RSpec.describe Api::HandoversApiController, type: :controller do
  let(:nomis_offender_id) { 'A1345AB' }
  let(:offender) { build(:offender, nomis_offender_id:) }

  it 'requires authentication' do
    get :show, params: { id: nomis_offender_id }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'when authenticated' do
    before { allow(controller).to receive(:verify_token) }

    describe 'GET /' do
      context "when no handover exists for offender" do
        it 'responds with 404' do
          get :show, params: { id: nomis_offender_id }, format: :json
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the handover exists" do
        let(:responsibility) { CalculatedHandoverDate::COMMUNITY_RESPONSIBLE }

        before do
          create(
            :calculated_handover_date,
            offender:,
            start_date: Date.new(2024, 6, 1),
            handover_date: Date.new(2024, 7, 1),
            responsibility:
          )
        end

        it "returns the handover in json form" do
          get :show, params: { id: nomis_offender_id }, format: :json

          expect(JSON.parse(response.body)).to include(
            'nomsNumber' => nomis_offender_id,
            'handoverStartDate' => '2024-06-01',
            'handoverDate' => '2024-07-01'
          )
        end

        context 'when the COM is responsible' do
          let(:responsibility) { CalculatedHandoverDate::COMMUNITY_RESPONSIBLE }

          it "reports as COM responsible" do
            create(:case_information, offender:, com_name: 'Com Nomis', com_email: 'com.nomis@community.gov.uk')

            get :show, params: { id: nomis_offender_id }, format: :json

            expect(JSON.parse(response.body)).to include(
              'responsibility' => 'COM',
              'responsibleComName' => 'Com Nomis',
              'responsibleComEmail' => 'com.nomis@community.gov.uk',
              'responsiblePomName' => nil,
              'responsiblePomNomisId' => nil,
            )
          end
        end

        context 'when the POM is responsible' do
          let(:responsibility) { CalculatedHandoverDate::CUSTODY_ONLY }

          it "reports as POM responsible" do
            create(:allocation_history, :with_prison, offender:, primary_pom_name: "Pom Nomis", primary_pom_nomis_id: 485_926)

            get :show, params: { id: nomis_offender_id }, format: :json

            expect(JSON.parse(response.body)).to include(
              'responsibility' => 'POM',
              'responsibleComName' => nil,
              'responsibleComEmail' => nil,
              'responsiblePomName' => 'Pom Nomis',
              'responsiblePomNomisId' => 485_926,
            )
          end
        end
      end
    end
  end
end
