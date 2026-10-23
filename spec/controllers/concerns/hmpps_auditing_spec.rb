require 'rails_helper'

RSpec.describe HmppsAuditing, type: :controller do
  include_context 'with audit event capture'

  controller(ApplicationController) do
    before_action :authenticate_user
    before_action :check_view_access

    audit_action :show, what: 'VIEW_ALLOCATION', subject_type: 'PRISONER_ID',
                        subject_id: -> { request.path_parameters.fetch(:id) },
                        success: -> { response.successful? && !params[:alternate] },
                        failure_reason: -> { 'Allocation view unavailable' if params[:alternate] }

    audit_action :create, what: 'CREATE_ALLOCATION', subject_type: 'PRISONER_ID',
                          subject_id: -> { params.fetch(:prisoner_id) },
                          failure_reason: -> { 'Allocation could not be created' }

    def create
      head :unprocessable_entity
    end

    def show
      render plain: 'Allocation'
    end

    def index
      render plain: 'Not audited'
    end

  private

    def check_view_access
      redirect_to '/401' if params[:denied]
      redirect_to '/404' if params[:missing]
      if params[:alternate]
        render plain: 'Different page'
      end
    end
  end

  before do
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

  it 'does not count an alternate page rendered by a before-action as success' do
    get :show, params: { id: 'A1234BC', alternate: true }

    expect(response).to have_http_status(:ok)
    expect(audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(audit_events.last[:details]).to eq('failureReason' => 'Allocation view unavailable')
  end

  it 'uses the event and failure reason belonging to the requested action' do
    post :create, params: { prisoner_id: 'A1234BC' }

    expect(audit_events.map { it[:what] }).to eq(%w[CREATE_ALLOCATION_ATTEMPT CREATE_ALLOCATION_FAILURE])
    expect(audit_events.last[:details]).to eq('failureReason' => 'Allocation could not be created')
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

    it 'preserves a permission denial redirect' do
      get :show, params: { id: 'A1234BC', denied: true }

      expect(response).to redirect_to('/401')
      expect(Rails.error).to have_received(:report).twice
    end
  end

  it 'does not audit undeclared actions' do
    get :index

    expect(audit_events).to be_empty
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

  it 'leaves the normal request unchanged when auditing is disabled' do
    allow(FeatureFlags).to receive(:hmpps_audit).and_return(double(enabled?: false))

    get :show, params: { id: 'A1234BC' }

    expect(response).to have_http_status(:ok)
    expect(audit_events).to be_empty
  end
end
