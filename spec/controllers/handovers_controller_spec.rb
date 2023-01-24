RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { 'DBG' }
  let(:prison) { instance_double Prison, :prison, code: prison_code }
  let(:default_params) { { prison_id: prison_code } }
  let(:staff_id) { 456_987 }
  let(:staff_member) { instance_double StaffMember, :staff_member, staff_id: staff_id }

  before do
    session[:new_handovers_ui] = true

    allow(Handover::CategorisedHandoverCasesForPom).to receive(:new).and_raise('Unexpected')
    allow(Handover::CategorisedHandoverCasesForHomd).to receive(:new).and_raise('Unexpected')
  end

  shared_examples 'handover cases list page' do |pom_view:|
    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has prison id' do
      expect(assigns(:prison_id)).to eq prison_code
    end

    it 'has handover cases list' do
      # handover_cases is defined in an inner describe block and is different per POM or HOMD user
      expect(assigns(:handover_cases)).to eq handover_cases
    end

    it 'sets current_handovers_url' do
      expect(flash[:current_handovers_url]).to eq request.url
    end

    it 'has correct POM view flag' do
      expect(assigns[:pom_view]).to eq pom_view
    end
  end

  shared_examples 'all handover cases list pages' do |pom_view:|
    describe 'upcoming handovers page' do
      before do
        get :upcoming, params: default_params
      end

      it_behaves_like 'handover cases list page', pom_view: pom_view
    end

    describe 'in progress handovers page' do
      before do
        get :in_progress, params: default_params
      end

      it_behaves_like 'handover cases list page', pom_view: pom_view
    end

    describe 'overdue tasks page' do
      before do
        get :overdue_tasks, params: default_params
      end

      it_behaves_like 'handover cases list page', pom_view: pom_view
    end

    describe 'COM allocation overdue page' do
      before do
        get :com_allocation_overdue, params: default_params
      end

      it_behaves_like 'handover cases list page', pom_view: pom_view
    end
  end

  describe 'when only POM authorised' do
    let(:handover_cases) { instance_double Handover::CategorisedHandoverCasesForPom, :handover_cases }

    before do
      stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
      allow(controller).to receive_messages(current_user_is_pom?: true)
      allow(controller).to receive_messages(current_user_is_spo?: false)
      allow(Handover::CategorisedHandoverCasesForPom).to receive(:new).with(staff_member).and_return(handover_cases)
    end

    it_behaves_like 'all handover cases list pages', pom_view: true
  end

  describe 'when only HOMD authorised' do
    let(:handover_cases) { instance_double Handover::CategorisedHandoverCasesForHomd, :handover_cases }

    before do
      stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
      allow(controller).to receive_messages(current_user_is_pom?: false)
      allow(controller).to receive_messages(current_user_is_spo?: true)
      allow(Handover::CategorisedHandoverCasesForHomd).to receive(:new).with(prison).and_return(handover_cases)
    end

    it_behaves_like 'all handover cases list pages', pom_view: false
  end

  describe 'when neither POM or HOMD authorised' do
    before do
      stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
      allow(controller).to receive_messages(current_user_is_pom?: false)
      allow(controller).to receive_messages(current_user_is_spo?: false)
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
