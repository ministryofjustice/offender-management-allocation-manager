# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            position: RecommendationService::PRISON_POM,
            staffId: 1
      )
    ]
  }

  before do
    stub_poms(prison, poms)
  end

  describe '#index' do
    context 'when logged in as POM' do
      render_views

      before do
        stub_signed_in_pom(prison, 1, 'alice')
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
        expect(response.body).not_to have_content('Newly arrived')
        expect(response.body).not_to have_content('View all offender managers')
        expect(response.body).not_to have_content('See case handover status')
      end
    end

    context 'when logged in as SPO' do
      render_views

      before do
        stub_sso_data(prison, 'alice')
        stub_request(:get, "#{ApiHelper::T3}/users/").
          to_return(body: { staffId: 1 }.to_json)
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
        expect(response.body).to have_content('Newly arrived')
        expect(response.body).to have_content('View all offender managers')
        expect(response.body).to have_content('See case handover status')
      end
    end
  end
end
