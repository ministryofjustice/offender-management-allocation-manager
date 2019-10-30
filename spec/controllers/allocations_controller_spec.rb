require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do
  let(:poms) {
    [
      {
        firstName: 'Alice',
        position: 'PRO',
        staffId: 1
      },
      {
        firstName: 'Bob',
        position: 'PRO',
        staffId: 2
      },
      {
        firstName: 'Clare',
        position: 'PO',
        staffId: 3
      },
      {
        firstName: 'Dave',
        position: 'PO',
        staffId: 4
      }
    ]
  }

  before do
    stub_sso_data(prison)

    stub_poms(prison, poms)
  end

  describe '#show' do
    let(:prison) { 'WEI' }

    context 'when POM has left' do
      let(:offender_no) { 'G7806VO' }
      let(:pom_staff_id) { 543_453 }
      let(:poms) {
        [{
          firstName: 'Alice',
          position: 'PRO',
          staffId: 123
        }]
      }

      before do
        stub_offender(offender_no)
        stub_poms(prison, poms)

        create(:case_information, nomis_offender_id: offender_no)
        create(:allocation_version, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id)

        stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/WEI/offender/G7806VO").
          to_return(status: 200, body: { staffId: 123_456 }.to_json, headers: {})
      end

      it 'redirects to the inactive POM page' do
        get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
        expect(response).to redirect_to(prison_pom_non_pom_path(prison, pom_staff_id))
      end
    end
  end

  describe '#new' do
    let(:prison) { 'WSI' }

    let(:offender_no) { 'G7806VO' }

    before do
      stub_offender(offender_no)
    end

    context 'when tier A offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'A')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Clare Dave])
      end
    end

    context 'when tier D offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'D')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Alice Bob])
      end
    end
  end
end
