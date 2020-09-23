require 'rails_helper'

RSpec.describe PrisonsController, type: :controller do
  describe '#index' do
    let(:prison) { 'LEI' }

    context 'when caseloads is not empty' do
      before do
        stub_sso_data(prison, 'spo')
      end

      it 'renders the dashboard page when caseload contains the active_prison' do
        get :index, params: { prison_id: prison }
        expect(response).to render_template("index")
      end

      it 'redirects to /401 when caseloads does not contain the active_prison' do
        get :index, params: { prison_id: 'WEI' }
        expect(response.status).to eq(302)
      end

      it 'redirects to /401 when the active_prison is not valid' do
        get :index, params: { prison_id: 'ABC' }
        expect(response.status).to eq(302)
      end
    end

    context 'when caseloads is nil' do
      it 'redirects to /401' do
        allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(OpenStruct.new(access_token: 'token'))
        session[:sso_data] = {}

        get :index, params: { prison_id: prison }
        expect(response.status).to eq(302)
      end
    end
  end
end
