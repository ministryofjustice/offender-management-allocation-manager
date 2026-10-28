require 'rails_helper'

RSpec.describe HmppsAuditing, type: :controller do
  include_context 'with audit event capture'

  controller(ApplicationController) do
    before_action :authenticate_user
    before_action :check_view_access

    def show
      render plain: 'Allocation'
    end

    def update
      return head :unprocessable_entity if params[:invalid]

      results = { 'results' => { 'returnedSubjectIds' => %w[A1234BC] } }
      if params[:too_many]
        audit(details: results, failure: 'Too many results')
        return head :unprocessable_entity
      end

      audit(details: results)
      render plain: 'A1234BC'
    end

    def index
      render plain: 'Not audited'
    end

    def destroy
      head :ok
    end

  private

    def check_view_access
      redirect_to '/401' if params[:denied]
      redirect_to '/404' if params[:missing]
      if params[:alternate]
        audit(failure: 'Allocation view unavailable')
        render plain: 'Different page'
      end
    end
  end

  before do
    allow(HmppsAudit::Actions).to receive(:all).and_return(
      HmppsAudit::Actions.parse(
        'anonymous#show' => { 'what' => 'VIEW_ALLOCATION', 'subject_type' => 'PRISONER_ID', 'subject_id' => 'id' },
        'anonymous#update' => { 'what' => 'SEARCH_ALLOCATION',
                                'subject_type' => 'SEARCH_TERM',
                                'subject_id' => 'id',
                                'query_params' => %w[page sort_by] },
        'anonymous#index' => { 'todo' => true }
      )
    )

    session[:sso_data] = {
      username: 'user-name', roles: [SsoIdentity::POM_ROLE], expiry: 1.hour.from_now.to_i
    }
    allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return('request-id')
  end

  it 'captures actor, requested subject and correlation for both events' do
    get :show, params: { id: 'A1234BC' }

    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_SUCCESS])
    expect(audit_events).to all(include(
                                  who: 'user-name', subject_type: 'PRISONER_ID', subject_id: 'A1234BC', correlation_id: 'request-id',
                                  details: {}
                                ))
  end

  it 'audits denial before the action runs' do
    get :show, params: { id: 'A1234BC', denied: true }

    expect(response).to redirect_to('/401')
    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(audit_events.last[:details]).to eq(
      'failureReason' => 'User does not have access to this data'
    )
  end

  it 'audits denial by the authentication role check, before later callbacks' do
    session[:sso_data][:roles] = []

    get :show, params: { id: 'A1234BC' }

    expect(response).to redirect_to('/401')
    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
  end

  it 'audits a missing requested resource without loading its subject' do
    get :show, params: { id: 'A1234BC', missing: true }

    expect(audit_events.last[:subject_id]).to eq('A1234BC')
    expect(audit_events.last[:details]).to include('failureReason' => 'Resource not found')
  end

  it 'uses a specific failure reason set by a callback, even for a successful response' do
    get :show, params: { id: 'A1234BC', alternate: true }

    expect(response).to have_http_status(:ok)
    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(audit_events.last[:details]).to eq('failureReason' => 'Allocation view unavailable')
  end

  describe 'details' do
    it 'sends present query params on every event and details added by the action on the outcome' do
      patch :update, params: { id: 'Smith', sort_by: 'name' }

      expect(audit_events.map { it[:details] }).to eq(
        [
          { 'queryParams' => { 'sortBy' => 'name' } },
          { 'queryParams' => { 'sortBy' => 'name' }, 'results' => { 'returnedSubjectIds' => %w[A1234BC] } },
        ]
      )
    end

    it 'uses a generic failure reason when the action does not add one' do
      patch :update, params: { id: 'Smith', page: '2', invalid: true }

      expect(audit_events.last).to include(
        what: 'SEARCH_ALLOCATION_FAILURE',
        details: { 'queryParams' => { 'page' => '2' }, 'failureReason' => 'Request failed validation' }
      )
    end

    it 'prefers a specific failure reason to the generic one, alongside details' do
      patch :update, params: { id: 'Smith', too_many: true }

      expect(audit_events.last).to include(
        what: 'SEARCH_ALLOCATION_FAILURE',
        details: { 'results' => { 'returnedSubjectIds' => %w[A1234BC] }, 'failureReason' => 'Too many results' }
      )
    end
  end

  it 'records rendering failures as failures, not successes' do
    allow(controller).to receive(:render).and_raise(RuntimeError, 'rendering failed')

    expect { get :show, params: { id: 'A1234BC' } }.to raise_error(RuntimeError, 'rendering failed')

    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
  end

  context 'when audit delivery fails' do
    before do
      allow(audit_client).to receive(:publish).and_raise(IOError, 'delivery failed')
      allow(Rails.error).to receive(:report)
    end

    it 'still renders the requested page and reports both failed deliveries' do
      get :show, params: { id: 'A1234BC' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('Allocation')
      expect(Rails.error).to have_received(:report).twice
    end
  end

  it 'does not audit actions that are not declared as audited' do
    get :index

    expect(response).to have_http_status(:ok)
    expect(audit_events).to be_empty
  end

  it 'raises for undeclared actions' do
    expect { delete :destroy, params: { id: 'A1234BC' } }.to raise_error(HmppsAudit::Actions::UndeclaredActionError)
  end

  it 'does not audit an unauthenticated user or change the authentication redirect' do
    session.delete(:sso_data)

    get :show, params: { id: 'A1234BC' }

    expect(response).to redirect_to('/auth/hmpps_sso')
    expect(audit_events).to be_empty
  end

  it 'does not audit expired identities' do
    session[:sso_data][:expiry] = 1.minute.ago.to_i

    get :show, params: { id: 'A1234BC' }

    expect(response).to redirect_to('/auth/hmpps_sso')
    expect(audit_events).to be_empty
  end

  context 'when auditing is disabled' do
    before { stub_feature_flag(:hmpps_audit, enabled: false) }

    it 'leaves the normal request unchanged' do
      get :show, params: { id: 'A1234BC' }

      expect(response).to have_http_status(:ok)
      expect(audit_events).to be_empty
    end

    it 'does not raise for undeclared actions' do
      delete :destroy, params: { id: 'A1234BC' }

      expect(response).to have_http_status(:ok)
    end
  end
end
