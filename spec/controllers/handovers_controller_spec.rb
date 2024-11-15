RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { 'DBG' }
  let(:prison) { instance_double Prison, :prison, code: prison_code }
  let(:default_params) { { prison_id: prison_code, pom: for_pom, sort: 'offender_last_name+asc' } }
  let(:staff_id) { 456_987 }
  let(:staff_member) { instance_double StaffMember, :staff_member, staff_id: staff_id }
  let(:handover_cases) do
    double :handover_cases, upcoming: double(:upcoming),
                            in_progress: double(:in_progress),
                            overdue_tasks: double(:overdue_tasks),
                            com_allocation_overdue: double(:com_allocation_overdue)
  end
  let(:for_pom) { 'for_pom' }
  let(:current_user_is_pom_stub) { double :current_user_is_pom_stub }
  let(:current_user_is_spo_stub) { double :current_user_is_spo_stub }
  let(:page) { double :page }

  before do
    stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
    allow(controller.helpers).to receive_messages(handover_cases_view: handover_cases)
    allow(controller).to receive_messages(current_user_is_pom?: current_user_is_pom_stub,
                                          current_user_is_spo?: current_user_is_spo_stub,
                                          page: page)
    allow(controller).to receive(:sort_and_paginate) { |arg| arg }
  end

  shared_examples 'handover cases list page' do |case_type|
    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has prison id' do
      expect(assigns(:prison_id)).to eq prison_code
    end

    it 'sets current_handovers_url' do
      expect(flash[:current_handovers_url]).to eq request.url
    end

    it 'has handover cases list' do
      expect(assigns(:handover_cases)).to eq handover_cases
    end

    describe '@pom_view' do
      context 'when the user is an spo but for_pom params is empty' do
        let(:for_pom) { nil }

        before { allow(controller).to receive(:current_user_is_spo?).and_return(true) }

        it 'is false' do
          expect(assigns[:pom_view]).to be(false)
        end
      end

      context 'when the user is an spo but for_pom params is user' do
        let(:for_pom) { 'user' }

        before { allow(controller).to receive(:current_user_is_spo?).and_return(true) }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end

      context 'when the user is a pom' do
        before { allow(controller).to receive(:current_user_is_pom?).and_return(true) }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end
    end

    it 'has correct paginated cases' do
      expect(assigns(:filtered_handover_cases)).to eq handover_cases.send(case_type)
    end

    it 'gets handover cases correctly' do
      expect(controller.helpers).to have_received(:handover_cases_view).with(
        current_user: staff_member,
        prison: prison,
        current_user_is_pom: current_user_is_pom_stub,
        current_user_is_spo: current_user_is_spo_stub,
        for_pom: for_pom
      )
    end
  end

  describe 'when user is authorised' do
    describe 'upcoming handovers page' do
      before do
        get :upcoming, params: default_params
      end

      it_behaves_like 'handover cases list page', :upcoming
    end

    describe 'in progress handovers page' do
      before do
        get :in_progress, params: default_params
      end

      it_behaves_like 'handover cases list page', :in_progress
    end

    describe 'overdue tasks page' do
      before do
        get :overdue_tasks, params: default_params
      end

      it_behaves_like 'handover cases list page', :overdue_tasks
    end

    describe 'COM allocation overdue page' do
      before do
        get :com_allocation_overdue, params: default_params
      end

      it_behaves_like 'handover cases list page', :com_allocation_overdue
    end
  end

  describe 'when user is not authorised' do
    before do
      allow(controller).to receive_messages(current_user_is_pom?: false, current_user_is_spo?: false)
    end

    describe 'upcoming handovers page' do
      it 'redirects to unauthorized' do
        get :upcoming, params: default_params
        expect(response).to redirect_to('/401')
      end
    end

    describe 'in progress handovers page' do
      it 'redirects to unauthorized' do
        get :in_progress, params: default_params
        expect(response).to redirect_to('/401')
      end
    end

    describe 'overdue tasks page' do
      it 'redirects to unauthorized' do
        get :overdue_tasks, params: default_params
        expect(response).to redirect_to('/401')
      end
    end

    describe 'COM allocation overdue page' do
      it 'redirects to unauthorized' do
        get :com_allocation_overdue, params: default_params
        expect(response).to redirect_to('/401')
      end
    end
  end

  describe 'when no sorting specified' do
    describe 'upcoming handovers page' do
      it 'defaults sort to handover_date+desc' do
        get :upcoming, params: default_params.except(:sort)
        expect(response).to redirect_to(
          upcoming_prison_handovers_path(default_params.merge(sort: 'handover_date asc')))
      end
    end

    describe 'in progress handovers page' do
      it 'defaults sort to handover_date+desc' do
        get :in_progress, params: default_params.except(:sort)
        expect(response).to redirect_to(
          in_progress_prison_handovers_path(default_params.merge(sort: 'handover_date asc')))
      end
    end

    describe 'overdue tasks page' do
      it 'defaults sort to handover_date+desc' do
        get :overdue_tasks, params: default_params.except(:sort)
        expect(response).to redirect_to(
          overdue_tasks_prison_handovers_path(default_params.merge(sort: 'handover_date asc')))
      end
    end

    describe 'COM allocation overdue page' do
      it 'defaults sort to handover_date+desc' do
        get :com_allocation_overdue, params: default_params.except(:sort)
        expect(response).to redirect_to(
          com_allocation_overdue_prison_handovers_path(default_params.merge(sort: 'handover_date asc')))
      end
    end
  end
end
