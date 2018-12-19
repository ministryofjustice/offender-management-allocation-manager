require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:sso_data) do
    { 'username' => 'Staff_one' }
  end

  let(:signon_identity) { double(SignonIdentity, to_session: sso_data) }

  describe '#create' do
    let(:auth_hash) { { 'info' => 'anything' } }

    subject(:create) { get :create, params: { provider: 'hmpps_sso' } }

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

  describe '#destroy' do
    before do
      allow(SignonIdentity).to receive(:from_omniauth).and_return(signon_identity)
      session[:sso_data] = sso_data
    end

    it 'deletes the session and redirects to Nomis Single Sign On' do
      nomis_oauth_host = 'http://nomis_sso'
      client_id = 'Bob'
      offender_manager_host = 'http://test:3000'
      nomis_oauth_sign_out_url =
        "#{nomis_oauth_host}/auth/logout?client_id=#{client_id}&redirect_uri=#{CGI.escape(offender_manager_host)}"

      allow(Rails.configuration).to receive(:nomis_oauth_host).and_return(nomis_oauth_host)
      allow(Rails.configuration).to receive(:nomis_oauth_client_id).and_return(client_id)
      allow(Rails.configuration).to receive(:offender_manager_host).and_return(offender_manager_host)

      expect(delete :destroy).to redirect_to(nomis_oauth_sign_out_url)
      expect(session[:sso_data]).to be_nil
    end
  end
end
