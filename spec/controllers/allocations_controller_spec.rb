require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do
  let(:prison) { 'WEI' }
  let(:poms) {
    [
      {
        firstName: 'Alice',
        position: 'PRO'
      },
      {
        firstName: 'Bob',
        position: 'PRO'
      },
      {
        firstName: 'Clare',
        position: 'PO'
      },
      {
        firstName: 'Dave',
        position: 'PO'
      }
    ]
  }

  before do
    stub_sso_data(prison)

    stub_poms(prison, poms)
  end

  describe '#new' do
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
