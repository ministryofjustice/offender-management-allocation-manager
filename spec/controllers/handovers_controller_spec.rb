RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { 'DBG' }
  let(:prison) { instance_double Prison, :prison, code: prison_code }
  let(:default_params) { { prison_id: prison_code, pom: pom_param } }
  let(:staff_id) { 456_987 }
  let(:staff_member) { instance_double StaffMember, :staff_member, staff_id: staff_id }
  let(:handover_cases) { double :handover_cases }
  let(:pom_param) { 'pom_param' }
  let(:pom_view_flag) { double :pom_view_flag }
  let(:current_user_is_pom_stub) { double :current_user_is_pom_stub }
  let(:current_user_is_spo_stub) { double :current_user_is_spo_stub }

  before do
    session[:new_handovers_ui] = true

    stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
    allow(controller.helpers).to receive_messages(handover_cases_view: [pom_view_flag, handover_cases])
    allow(controller).to receive_messages(current_user_is_pom?: current_user_is_pom_stub)
    allow(controller).to receive_messages(current_user_is_spo?: current_user_is_spo_stub)
  end

  shared_examples 'handover cases list page' do
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

    it 'has correct POM view flag' do
      expect(assigns[:pom_view]).to eq pom_view_flag
    end

    it 'gets handover cases correctly' do
      expect(controller.helpers).to have_received(:handover_cases_view).with(
        current_user: staff_member,
        prison: prison,
        current_user_is_pom: current_user_is_pom_stub,
        current_user_is_spo: current_user_is_spo_stub,
        pom_param: pom_param,
      )
    end
  end

  describe 'when user is authorised' do
    describe 'upcoming handovers page' do
      before do
        get :upcoming, params: default_params
      end

      it_behaves_like 'handover cases list page'
    end

    describe 'in progress handovers page' do
      before do
        get :in_progress, params: default_params
      end

      it_behaves_like 'handover cases list page'
    end

    describe 'overdue tasks page' do
      before do
        get :overdue_tasks, params: default_params
      end

      it_behaves_like 'handover cases list page'
    end

    describe 'COM allocation overdue page' do
      before do
        get :com_allocation_overdue, params: default_params
      end

      it_behaves_like 'handover cases list page'
    end
  end

  describe 'when user is not authorised' do
    before do
      allow(controller.helpers).to receive_messages(handover_cases_view: nil)
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
end
