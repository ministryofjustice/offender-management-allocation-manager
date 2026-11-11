require 'rails_helper'

RSpec.describe HmppsAuditing, type: :controller do
  include_context 'with HMPPS audit event capture'

  controller(ApplicationController) do
    before_action :authenticate_user
    before_action :check_view_access

    def show
      render plain: 'Allocation'
    end

    def update
      if params[:saved]
        audit(details: { 'saved' => true })
        audit(failure: 'Operation failed') if params[:failed]
        raise 'After save failed' if params[:raise_after_save]

        return redirect_to '/completed'
      end

      return head :unprocessable_entity if params[:invalid]

      results = params[:empty] ? [] : %w[A1234BC]
      if params[:too_many]
        audit(details: { 'limit' => 0 }, results:, failure: 'Too many results')
        return head :unprocessable_entity
      end

      audit(results:)
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
      redirect_to '/other-prison' if params[:wrong_prison]
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
                                'query_params' => %w[page sort_by pom_ids] },
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

    expect(hmpps_audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_SUCCESS])
    expect(hmpps_audit_events).to all(include(
                                        who: 'user-name', subject_type: 'PRISONER_ID', subject_id: 'A1234BC', correlation_id: 'request-id',
                                        details: {}
                                      ))
  end

  it 'audits denial before the action runs' do
    get :show, params: { id: 'A1234BC', denied: true }

    expect(response).to redirect_to('/401')
    expect(hmpps_audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(hmpps_audit_events.last[:details]).to eq(
      'failureReason' => 'User does not have access to this data'
    )
  end

  it 'treats a callback redirect to an ordinary page as failure because the action did not run' do
    get :show, params: { id: 'A1234BC', wrong_prison: true }

    expect(response).to redirect_to('/other-prison')
    expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION', outcome: 'FAILURE')
    expect(hmpps_audit_events.last[:details]).to eq('failureReason' => 'Request redirected before completing the operation')
  end

  it 'audits a missing requested resource without loading its subject' do
    get :show, params: { id: 'A1234BC', missing: true }

    expect(hmpps_audit_events.last[:subject_id]).to eq('A1234BC')
    expect(hmpps_audit_events.last[:details]).to include('failureReason' => 'Resource not found')
  end

  it 'uses a specific failure reason set by a callback, even for a successful response' do
    get :show, params: { id: 'A1234BC', alternate: true }

    expect(response).to have_http_status(:ok)
    expect(hmpps_audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(hmpps_audit_events.last[:details]).to eq('failureReason' => 'Allocation view unavailable')
  end

  describe 'details' do
    it 'always deduplicates explicitly provided subject IDs' do
      allow(controller).to receive(:audit).and_wrap_original do |method, **options|
        options[:results] *= 2 if options[:results]
        method.call(**options)
      end

      patch :update, params: { id: 'Smith' }

      expect(hmpps_audit_events.last[:details]['results']).to eq(
        'resultCount' => 1, 'returnedSubjectIds' => ['A1234BC']
      )
    end

    it 'includes the route prison on both events alongside query params and outcome details' do
      routes.draw { patch '/prisons/:prison_id/allocation/:id' => 'anonymous#update' }

      patch :update, params: { prison_id: 'LEI', id: 'Smith', page: '2', saved: true }

      expect(hmpps_audit_events.pluck(:details)).to eq([
        { 'prisonId' => 'LEI', 'queryParams' => { 'page' => '2' } },
        { 'prisonId' => 'LEI', 'queryParams' => { 'page' => '2' }, 'saved' => true },
      ])
    end

    describe 'configured results' do
      let(:items) { [double(offender_no: 'A1234BC')] }

      before do
        routes.draw { get '/list' => 'anonymous#show' }
        config = HmppsAudit::Actions.parse(
          'anonymous#show' => {
            'what' => 'VIEW_ALLOCATION_LIST',
            'subject_type' => 'NOT_APPLICABLE',
            'results' => { 'collections' => %w[cases recent_cases], 'id' => 'offender_no' }
          }
        ).fetch('anonymous#show')
        allow(HmppsAudit::Actions).to receive(:find).with('anonymous', 'show').and_return(config)
        allow(controller).to receive(:render).and_wrap_original do |method, **options|
          controller.instance_variable_set(:@cases, items)
          controller.instance_variable_set(:@recent_cases, items)
          method.call(**options)
        end
      end

      it 'collects unique IDs across rendered collections only on the outcome' do
        get :show

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST')
        expect(hmpps_audit_events.first[:details]).to eq({})
        expect(hmpps_audit_events.last[:details]['results']).to eq(
          'resultCount' => 1, 'returnedSubjectIds' => ['A1234BC']
        )
      end

      context 'with empty collections' do
        let(:items) { [] }

        it 'records zero results' do
          get :show

          expect(hmpps_audit_events.last[:details]['results']).to eq(
            'resultCount' => 0, 'returnedSubjectIds' => []
          )
        end
      end

      it 'does not collect results for denied or redirected requests' do
        get :show, params: { denied: true }

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).not_to have_key('results')
      end

      it 'does not collect results for an explicitly failed alternate page' do
        get :show, params: { alternate: true }

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).not_to have_key('results')
      end

      it 'does not collect results when rendering fails' do
        allow(controller).to receive(:render).and_raise(RuntimeError, 'rendering failed')

        expect { get :show }.to raise_error(RuntimeError, 'rendering failed')

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).not_to have_key('results')
      end

      it 'does not collect results for a completed action redirect' do
        allow(controller).to receive(:render) { controller.redirect_to('/completed') }

        get :show

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST')
        expect(hmpps_audit_events.last[:details]).not_to have_key('results')
      end

      it 'does not collect results for error responses' do
        allow(controller).to receive(:render) { controller.head(:unprocessable_entity) }

        get :show

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).not_to have_key('results')
      end

      it 'does not collect results when auditing is disabled' do
        stub_feature_flag(:hmpps_audit, enabled: false)
        allow(controller).to receive(:render).and_call_original

        get :show

        expect(response).to be_successful
        expect(hmpps_audit_events).to be_empty
      end

      it 'raises for a missing configured collection instead of reporting an empty list' do
        allow(controller).to receive(:render).and_call_original

        expect { get :show }.to raise_error(KeyError, /Missing audit results collection @cases/)

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
      end

      it 'raises for a misconfigured ID method' do
        items.replace([Object.new])

        expect { get :show }.to raise_error(NoMethodError, /offender_no/)

        expect(hmpps_audit_events).to have_recorded_event('VIEW_ALLOCATION_LIST', outcome: 'FAILURE')
      end
    end

    it 'includes the route prison when a callback denies access' do
      routes.draw { get '/prisons/:prison_id/allocation/:id' => 'anonymous#show' }

      get :show, params: { prison_id: 'LEI', id: 'A1234BC', denied: true }

      expect(hmpps_audit_events).to all(include(details: hash_including('prisonId' => 'LEI')))
    end

    it 'does not infer a prison from query parameters on an unscoped route' do
      get :show, params: { id: 'A1234BC', prison_id: 'LEI' }

      expect(hmpps_audit_events.pluck(:details)).to eq([{}, {}])
    end

    it 'captures flat string arrays without including blank values or nested structures' do
      patch :update, params: { id: 'Smith', pom_ids: [' 123 ', '', '456', { private: 'notes' }, ['789']] }

      expect(hmpps_audit_events).to all(include(details: hash_including('queryParams' => { 'pomIds' => %w[123 456] })))
    end

    it 'sends present query params on every event and details added by the action on the outcome' do
      patch :update, params: { id: 'Smith', sort_by: 'name' }

      expect(hmpps_audit_events.map { it[:details] }).to eq(
        [
          { 'queryParams' => { 'sortBy' => 'name' } },
          { 'queryParams' => { 'sortBy' => 'name' }, 'results' => { 'resultCount' => 1, 'returnedSubjectIds' => %w[A1234BC] } },
        ]
      )
    end

    it 'records empty results with a zero count' do
      patch :update, params: { id: 'Smith', empty: true }

      expect(hmpps_audit_events.last[:details]).to eq('results' => { 'resultCount' => 0, 'returnedSubjectIds' => [] })
    end

    it 'uses a generic failure reason when the action does not add one' do
      patch :update, params: { id: 'Smith', page: '2', invalid: true }

      expect(hmpps_audit_events.last).to include(
        what: 'SEARCH_ALLOCATION_FAILURE',
        details: { 'queryParams' => { 'page' => '2' }, 'failureReason' => 'Request failed validation' }
      )
    end

    it 'prefers a specific failure reason to the generic one, alongside details' do
      patch :update, params: { id: 'Smith', too_many: true }

      expect(hmpps_audit_events.last).to include(
        what: 'SEARCH_ALLOCATION_FAILURE',
        details: {
          'limit' => 0,
          'results' => { 'resultCount' => 1, 'returnedSubjectIds' => %w[A1234BC] },
          'failureReason' => 'Too many results'
        }
      )
    end
  end

  it 'records rendering failures as failures, not successes' do
    routes.draw { get '/prisons/:prison_id/allocation/:id' => 'anonymous#show' }
    allow(controller).to receive(:render).and_raise(RuntimeError, 'rendering failed')

    expect { get :show, params: { prison_id: 'LEI', id: 'A1234BC' } }.to raise_error(RuntimeError, 'rendering failed')

    expect(hmpps_audit_events.map { it[:what] }).to eq(%w[VIEW_ALLOCATION_ATTEMPT VIEW_ALLOCATION_FAILURE])
    expect(hmpps_audit_events).to all(include(details: hash_including('prisonId' => 'LEI')))
  end

  it 'treats a completed action redirect as success without an explicit signal' do
    patch :update, params: { id: 'Smith', saved: true }

    expect(response).to redirect_to('/completed')
    expect(hmpps_audit_events).to have_recorded_event('SEARCH_ALLOCATION', subject_id: 'Smith')
    expect(hmpps_audit_events.last[:details]).to eq('saved' => true)
  end

  it 'prefers explicit failure over a normal redirect' do
    patch :update, params: { id: 'Smith', saved: true, failed: true }

    expect(hmpps_audit_events).to have_recorded_event('SEARCH_ALLOCATION', outcome: 'FAILURE')
    expect(hmpps_audit_events.last[:details]).to eq('saved' => true, 'failureReason' => 'Operation failed')
  end

  it 'records and propagates an exception after persistence details were added' do
    expect {
      patch :update, params: { id: 'Smith', saved: true, raise_after_save: true }
    }.to raise_error(RuntimeError, 'After save failed')

    expect(hmpps_audit_events).to have_recorded_event('SEARCH_ALLOCATION', outcome: 'FAILURE')
  end

  describe 'auditable_entity' do
    it 'ignores unsaved records and form objects' do
      [build(:early_allocation, id: 123), EarlyAllocationDateForm.new].each do |entity|
        allow(controller).to receive(:auditable_entity).and_return(entity)

        get :show, params: { id: 'A1234BC' }

        expect(hmpps_audit_events.last[:details]).to eq({})
      end
    end

    it 'includes the entity ID only on the outcome, even after deletion' do
      entity = create(:early_allocation)
      entity.destroy!
      allow(controller).to receive(:auditable_entity).and_return(entity)

      get :show, params: { id: 'A1234BC' }

      expect(hmpps_audit_events.map { it[:details] }).to eq([{}, { 'entityId' => entity.id }])
    end

    it 'includes the entity ID when the application raises' do
      entity = create(:early_allocation)
      allow(controller).to receive(:auditable_entity).and_return(entity)

      expect {
        patch :update, params: { id: 'Smith', saved: true, raise_after_save: true }
      }.to raise_error(RuntimeError, 'After save failed')

      expect(hmpps_audit_events.last[:details]).to include('entityId' => entity.id)
    end
  end

  context 'when audit delivery fails' do
    before do
      allow(hmpps_audit_client).to receive(:publish).and_raise(IOError, 'delivery failed')
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
    expect(hmpps_audit_events).to be_empty
  end

  it 'raises for undeclared actions' do
    expect { delete :destroy, params: { id: 'A1234BC' } }.to raise_error(HmppsAudit::Actions::UndeclaredActionError)
  end

  it 'does not audit an unauthenticated user or change the authentication redirect' do
    session.delete(:sso_data)

    get :show, params: { id: 'A1234BC' }

    expect(response).to redirect_to('/auth/hmpps_sso')
    expect(hmpps_audit_events).to be_empty
  end

  it 'does not audit expired identities' do
    session[:sso_data][:expiry] = 1.minute.ago.to_i

    get :show, params: { id: 'A1234BC' }

    expect(response).to redirect_to('/auth/hmpps_sso')
    expect(hmpps_audit_events).to be_empty
  end

  context 'when auditing is disabled' do
    before { stub_feature_flag(:hmpps_audit, enabled: false) }

    it 'leaves the normal request unchanged' do
      get :show, params: { id: 'A1234BC' }

      expect(response).to have_http_status(:ok)
      expect(hmpps_audit_events).to be_empty
    end

    it 'does not raise for undeclared actions' do
      delete :destroy, params: { id: 'A1234BC' }

      expect(response).to have_http_status(:ok)
    end
  end
end
