require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  include_context 'with HMPPS audit event capture'

  let(:sso_data) do
    { 'username' => 'Staff_one', 'user_uuid' => '11111111-2222-3333-4444-555555555555', 'active_caseload' => 'LEI' }
  end

  let(:signon_identity) do
    instance_double(SignonIdentity, attributes: sso_data, username: sso_data.fetch('username'),
                                    active_caseload: sso_data.fetch('active_caseload'))
  end

  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return('auth-request-id')
  end

  describe '#create' do
    subject(:create) { get :create, params: { provider: 'hmpps_sso' } }

    let(:auth_hash) { { 'info' => 'anything' } }

    before do
      request.env['omniauth.auth'] = auth_hash
    end

    context "when the user can't be signed in" do
      before do
        allow(SignonIdentity).to receive(:from_omniauth).and_return(nil)
      end

      it 'redirects without reporting a successful sign-in' do
        expect(create).to redirect_to(root_path)
        expect(hmpps_auth_audit_events).to be_empty
      end
    end

    context 'when the user can be signed in' do
      before do
        allow(SignonIdentity).to receive(:from_omniauth).and_return(signon_identity)
      end

      it 'sets the identity data in the session' do
        session[:sso_data] = { username: 'previous-user', expiry: 1.hour.from_now.to_i }
        session['allocation_override:LEI:G1234AB:456'] = { override_reasons: ['continuity'] }
        session['flash'] = { 'discard' => [], 'flashes' => { 'notice' => 'Leeds (HMP) selected' } }
        create

        expect(session[:sso_data]).to eq(sso_data)
        expect(session['allocation_override:LEI:G1234AB:456']).to be_nil
        expect(flash[:notice]).to eq('Leeds (HMP) selected')
        expect(response).to redirect_to(prison_dashboard_index_path('LEI'))
        expect(hmpps_auth_audit_events).to eq([
          { what: 'AUTH_USER_SIGN_IN_ATTEMPT',
            who: 'Staff_one',
            subject_type: 'NOT_APPLICABLE',
            subject_id: nil,
            correlation_id: 'auth-request-id',
            details: {} },
          { what: 'AUTH_USER_SIGN_IN_SUCCESS',
            who: 'Staff_one',
            subject_type: 'NOT_APPLICABLE',
            subject_id: nil,
            correlation_id: 'auth-request-id',
            details: {} }
        ])
      end

      it 'reports a failure and propagates the error when establishing the session fails' do
        allow(controller).to receive(:save_to_session).and_raise(IOError, 'Session unavailable')

        expect { create }.to raise_error(IOError, 'Session unavailable')
        expect(hmpps_auth_audit_events).to eq([
          { what: 'AUTH_USER_SIGN_IN_ATTEMPT',
            who: 'Staff_one',
            subject_type: 'NOT_APPLICABLE',
            subject_id: nil,
            correlation_id: 'auth-request-id',
            details: {} },
          { what: 'AUTH_USER_SIGN_IN_FAILURE',
            who: 'Staff_one',
            subject_type: 'NOT_APPLICABLE',
            subject_id: nil,
            correlation_id: 'auth-request-id',
            details: { 'failureReason' => 'Application failed to complete the operation: IOError' } }
        ])
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
        it 'redirects directly to the freshly selected prison dashboard' do
          expect(create).to redirect_to(prison_dashboard_index_path('LEI'))
        end
      end

      %i[root_path root_url].each do |root_destination|
        context "with #{root_destination} as the saved destination" do
          it 'skips root while preserving the caseload change notice' do
            session[:redirect_path] = controller.public_send(root_destination)
            session['flash'] = { 'discard' => [], 'flashes' => { 'notice' => 'Leeds (HMP) selected' } }

            create

            expect(response).to redirect_to(prison_dashboard_index_path('LEI'))
            expect(flash[:notice]).to eq('Leeds (HMP) selected')
            expect(session[:redirect_path]).to be_nil
          end
        end
      end

      it 'preserves a prison-scoped destination and its caseload change notice' do
        session[:redirect_path] = prison_dashboard_index_path('LEI')
        session['flash'] = { 'discard' => [], 'flashes' => { 'notice' => 'Leeds (HMP) selected' } }

        create

        expect(response).to redirect_to(prison_dashboard_index_path('LEI'))
        expect(flash[:notice]).to eq('Leeds (HMP) selected')
      end

      context 'without an active caseload' do
        let(:sso_data) { super().merge('active_caseload' => nil) }

        it 'retains the root fallback' do
          expect(create).to redirect_to(root_url)
        end
      end
    end
  end

  describe '#destroy' do
    before do
      allow(SignonIdentity).to receive(:from_omniauth).and_return(signon_identity)
      session[:sso_data] = sso_data.merge('expiry' => 1.hour.from_now.to_i)
      session['allocation_override:LEI:G1234AB:456'] = { override_reasons: ['continuity'] }
    end

    it 'deletes the session and redirects to Nomis Single Sign On' do
      nomis_oauth_host = 'http://nomis_sso'
      client_id = 'Bob'
      allocation_manager_host = 'http://test:3000'
      nomis_oauth_sign_out_url =
        "#{nomis_oauth_host}/auth/logout?client_id=#{client_id}&redirect_uri=#{CGI.escape(allocation_manager_host)}"

      allow(Rails.configuration).to receive(:nomis_oauth_host).and_return(nomis_oauth_host)
      allow(Rails.configuration).to receive(:hmpps_oauth_client_id).and_return(client_id)
      allow(Rails.configuration).to receive(:allocation_manager_host).and_return(allocation_manager_host)

      expect(delete :destroy).to redirect_to(nomis_oauth_sign_out_url)
      expect(session[:sso_data]).to be_nil
      expect(session['allocation_override:LEI:G1234AB:456']).to be_nil
      expect(hmpps_auth_audit_events).to eq([
        { what: 'AUTH_USER_SIGN_OUT_ATTEMPT',
          who: 'Staff_one',
          subject_type: 'NOT_APPLICABLE',
          subject_id: nil,
          correlation_id: 'auth-request-id',
          details: {} },
        { what: 'AUTH_USER_SIGN_OUT_SUCCESS',
          who: 'Staff_one',
          subject_type: 'NOT_APPLICABLE',
          subject_id: nil,
          correlation_id: 'auth-request-id',
          details: {} }
      ])
    end

    it 'reports a failure and propagates the error when session reset fails' do
      allow(controller).to receive(:reset_session).and_raise(IOError, 'Session unavailable')

      expect { get :destroy }.to raise_error(IOError, 'Session unavailable')
      expect(hmpps_auth_audit_events.map { it.fetch(:what) }).to eq(
        %w[AUTH_USER_SIGN_OUT_ATTEMPT AUTH_USER_SIGN_OUT_FAILURE]
      )
      expect(hmpps_auth_audit_events.last).to include(
        who: 'Staff_one',
        details: { 'failureReason' => 'Application failed to complete the operation: IOError' }
      )
    end

    it 'clears an expired session without auditing' do
      session[:sso_data]['expiry'] = 1.hour.ago.to_i

      get :destroy

      expect(response).to be_redirect
      expect(session[:sso_data]).to be_nil
      expect(hmpps_auth_audit_events).to be_empty
    end

    it 'does not report a sign-out for an absent session' do
      session.delete(:sso_data)

      get :destroy

      expect(response).to be_redirect
      expect(hmpps_auth_audit_events).to be_empty
    end
  end

  describe 'failure' do
    it 'renders the error page' do
      get :failure

      expect(response).to render_template('failure')
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
