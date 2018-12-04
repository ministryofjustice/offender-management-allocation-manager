require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe '#create' do
    subject(:create) { get :create, params: { provider: 'hmpps_sso' } }

    let(:auth_hash) { { 'info' => anything } }
    let(:sso_data) do
      {
        'username': 'Staff_one'
      }
    end

    before do
      request.env['omniauth.auth'] = auth_hash
    end

    context "when the user can't be signed in" do
      before do
        allow(SignonIdentity).to receive(:from_omniauth).and_return(nil)
      end

      it { is_expected.to redirect_to(root_path) }
    end

    context 'when the user can be signed in' do
      let(:signon_identity) { double(SignonIdentity, to_session: sso_data) }

      before do
        allow(SignonIdentity).to receive(:from_omniauth).and_return(signon_identity)
      end

      it 'sets the identity data in the session' do
        create
        expect(session[:sso_data]).to eq(sso_data)
      end

      context 'with a redirect_path set on the session' do
        let(:redirect_path) { '/health' }

        before do
          session[:redirect_path] = '/health'
        end

        it 'clears the redirect from the session and redirects' do
          expect(create).to redirect_to(redirect_path)
          expect(session[:redirect_path]).to be_nil
        end
      end

      context 'with no redirect_path set on the session' do
        it 'redirects to the root by default' do
          expect(create).to redirect_to(root_url)
        end
      end
    end
  end
end
