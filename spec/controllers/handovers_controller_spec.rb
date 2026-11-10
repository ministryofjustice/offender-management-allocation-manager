describe HandoversController do
  include_context 'with HMPPS audit event capture'

  let(:prison) { double(code: 'DBG') }
  let(:default_params) { { prison_id: prison.code, pom: for_pom, sort: 'offender_last_name+asc' } }
  let(:staff_member) { double(staff_id: 456_987) }
  let(:handover_cases) do
    double :handover_cases, upcoming: [handover_case],
                            in_progress: [handover_case],
                            overdue_tasks: [handover_case],
                            com_allocation_overdue: [handover_case]
  end
  let(:handover_case) { double(offender: double(offender_no: 'A1234BC')) }
  let(:for_pom) { 'user' }
  let(:current_user_is_pom) { double :current_user_is_pom }
  let(:current_user_is_spo) { double :current_user_is_spo }

  before do
    stub_sso_data(prison.code)
    stub_high_level_staff_member_auth(prison:, staff_member:)

    allow(controller.helpers).to receive(:handover_cases_view).with(
      current_user: staff_member,
      prison:,
      current_user_is_pom:,
      current_user_is_spo:,
      for_pom:
    ).and_return(handover_cases)

    allow(controller).to receive_messages(
      current_user_is_pom?: current_user_is_pom,
      current_user_is_spo?: current_user_is_spo
    )

    allow(controller).to receive(:sort_and_paginate) { |arg| arg }
  end

  shared_examples 'handover cases list page' do |case_type, event|
    let(:with_sort) { true }
    let(:params) { with_sort ? default_params : default_params.except(:sort) }

    before do
      get case_type, params:
    end

    it 'renders successfully' do
      expect(response).to be_successful
      expect(hmpps_audit_events).to have_recorded_event(event, subject_type: 'NOT_APPLICABLE', subject_id: nil)
      context = {
        'prisonId' => prison.code,
        'queryParams' => { 'pom' => for_pom, 'sort' => default_params.fetch(:sort) }
      }
      expect(hmpps_audit_events.first[:details]).to eq(context)
      expect(hmpps_audit_events.last[:details]).to eq(
        context.merge('results' => { 'resultCount' => 1, 'returnedSubjectIds' => ['A1234BC'] })
      )
    end

    it 'has prison id' do
      expect(assigns(:prison_id)).to eq prison.code
    end

    it 'sets current_handovers_url' do
      expect(flash[:current_handovers_url]).to eq request.url
    end

    it 'has handover cases list' do
      expect(assigns(:handover_cases)).to eq handover_cases
    end

    describe '@pom_view' do
      context 'when the user is an spo but for_pom params is empty' do
        let(:for_pom) { '' }
        let(:current_user_is_spo) { true }

        it 'is false' do
          expect(assigns[:pom_view]).to be(false)
        end
      end

      context 'when the user is an spo but for_pom params is user' do
        let(:for_pom) { 'user' }
        let(:current_user_is_spo) { true }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end

      context 'when the user is a pom' do
        let(:current_user_is_pom) { true }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end
    end

    it 'has correct paginated cases' do
      expect(assigns(:filtered_handover_cases)).to eq handover_cases.send(case_type)
    end

    context 'when no sorting specified' do
      let(:with_sort) { false }

      it 'renders directly with the default sort and one audit interaction' do
        expect(response).to be_successful
        expect(controller.params[:sort]).to eq('handover_date asc')
        expect(flash[:current_handovers_url]).to eq(request.url)
        expect(hmpps_audit_events).to have_recorded_event(event, subject_type: 'NOT_APPLICABLE', subject_id: nil)
        expect(hmpps_audit_events.last[:details]['results']).to eq(
          'resultCount' => 1, 'returnedSubjectIds' => ['A1234BC']
        )
      end

      context 'when sorting and paginating the cases' do
        let(:earlier_case) { double(handover_date: Date.new(2026, 11, 1), offender: double(offender_no: 'B1234CD')) }
        let(:later_case) { double(handover_date: Date.new(2026, 12, 1), offender: double(offender_no: 'C1234DE')) }
        let(:params) { default_params.except(:sort).merge(page: '2') }

        before do
          allow(handover_cases).to receive(case_type).and_return([later_case, earlier_case])
          allow(controller).to receive(:sort_and_paginate).and_call_original
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)
          hmpps_audit_events.clear

          get case_type, params:
        end

        it 'preserves the requested page and sorts by handover date ascending' do
          expect(response).to be_successful
          expect(assigns(:filtered_handover_cases)).to eq([later_case])
          expect(hmpps_audit_events).to have_recorded_event(event)
          expect(hmpps_audit_events.last[:details]['results']).to eq(
            'resultCount' => 1, 'returnedSubjectIds' => ['C1234DE']
          )
        end
      end

      context 'when the sort parameter is blank' do
        let(:params) { default_params.merge(sort: '') }

        it 'renders directly using the default sort' do
          expect(response).to be_successful
          expect(controller.params[:sort]).to eq('handover_date asc')
          expect(hmpps_audit_events).to have_recorded_event(event)
        end
      end

      context 'when the user is not authorised' do
        let(:current_user_is_pom) { false }
        let(:current_user_is_spo) { false }

        it 'still redirects to unauthorized and audits the failure' do
          expect(response).to redirect_to('/401')
          expect(hmpps_audit_events).to have_recorded_event(event, outcome: 'FAILURE')
          expect(hmpps_audit_events.last[:details]).not_to have_key('results')
        end
      end
    end

    describe 'when user is not authorised' do
      let(:current_user_is_pom) { false }
      let(:current_user_is_spo) { false }

      it 'redirects to unauthorized' do
        get case_type, params: default_params
        expect(response).to redirect_to('/401')
      end
    end
  end

  it_behaves_like 'handover cases list page', :upcoming, 'VIEW_UPCOMING_HANDOVERS_LIST'
  it_behaves_like 'handover cases list page', :in_progress, 'VIEW_HANDOVERS_IN_PROGRESS_LIST'
  it_behaves_like 'handover cases list page', :overdue_tasks, 'VIEW_HANDOVER_OVERDUE_TASKS_LIST'
  it_behaves_like 'handover cases list page', :com_allocation_overdue, 'VIEW_COM_ALLOCATION_OVERDUE_LIST'

  it 'audits the requested handover page rather than the whole list' do
    cases = [
      double(offender_last_name: 'Alpha', offender: double(offender_no: 'A1234BC')),
      double(offender_last_name: 'Bravo', offender: double(offender_no: 'B1234CD')),
    ]
    allow(handover_cases).to receive(:upcoming).and_return(cases)
    allow(controller).to receive(:sort_and_paginate).and_call_original
    allow(Kaminari.config).to receive(:default_per_page).and_return(1)

    get :upcoming, params: default_params.merge(sort: 'offender_last_name asc', page: '2')

    expect(hmpps_audit_events.last[:details]['results']).to eq(
      'resultCount' => 1, 'returnedSubjectIds' => ['B1234CD']
    )
  end
end
