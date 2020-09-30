require 'rails_helper'

RSpec.describe SearchController, type: :controller do
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
    stub_signed_in_pom(prison, 1, 'alice')
  end

  context 'when user is a POM ' do
    before do
      stub_signed_in_pom(prison, 1, 'alice')
    end

    it 'user is redirected to caseload' do
      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response).to redirect_to(prison_staff_caseload_index_path(prison, 1, q: 'Cal'))
    end
  end

  context 'when user is an SPO ' do
    before do
      stub_sso_data(prison)
    end

    it 'can search' do
      offenders = build_list(:nomis_offender, 1)
      stub_offenders_for_prison(prison, offenders)

      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response.status).to eq(200)
      expect(response).to be_successful

      expect(assigns(:q)).to eq('Cal')
      expect(assigns(:offenders).size).to eq(0)
    end
  end
end
