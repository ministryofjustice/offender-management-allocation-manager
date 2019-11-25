require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe '#index' do
    let(:prison) { 'LEI' }
    let(:poms) {
      [
        {
          firstName: 'Alice',
          position: RecommendationService::PRISON_POM,
          staffId: 1
        }
      ]
    }

    context 'when logged in as POM' do
      render_views

      before do
        stub_poms(prison, poms)
        stub_sso_pom_data(prison)
        stub_signed_in_pom(1, 'Alice')
        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
          with(headers: { 'Authorization' => 'Bearer token' }).
          to_return(status: 200, body: { staffId: 1 }.to_json, headers: {})
      end

      it 'shows me only Manage case tasks' do
        get :index, params: { prison_id: prison }
        expect(response).to render_template("index")

        expect(assigns(:is_pom)).to be true
        expect(assigns(:is_spo)).to be false

        expect(response.body).to have_content('See your caseload')
        expect(response.body).to have_content('See new allocations')
        expect(response.body).to have_content('See cases close to handover')
        expect(response.body).to have_content('Case updates needed')

        expect(response.body).not_to have_content('See all allocated prisoners')
        expect(response.body).not_to have_content('Make new allocations')
        expect(response.body).not_to have_content('Update case information')
        expect(response.body).not_to have_content('View all offender managers')
      end
    end

    context 'when logged in as POM' do
      render_views

      before do
        stub_poms(prison, poms)
        stub_sso_data(prison)
        stub_signed_in_pom(1, 'Alice')
        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
          with(headers: { 'Authorization' => 'Bearer token' }).
          to_return(status: 200, body: { staffId: 1 }.to_json, headers: {})
      end

      it 'shows me only SPO tasks' do
        get :index, params: { prison_id: prison }
        expect(response).to render_template("index")

        expect(assigns(:is_pom)).to be false
        expect(assigns(:is_spo)).to be true

        expect(response.body).not_to have_content('See your caseload')
        expect(response.body).not_to have_content('See new allocations')
        expect(response.body).not_to have_content('See cases close to handover')
        expect(response.body).not_to have_content('Case updates needed')

        expect(response.body).to have_content('See all allocated prisoners')
        expect(response.body).to have_content('Make new allocations')
        expect(response.body).to have_content('Update case information')
        expect(response.body).to have_content('View all offender managers')
      end
    end
  end
end
