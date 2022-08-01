RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { 'DBG' }
  let(:prison) { instance_double Prison, :prison, code: prison_code }
  let(:default_params) { { new_handover: NEW_HANDOVER_TOKEN, prison_id: prison_code } }
  let(:staff_id) { 456_987 }
  let(:pom_staff_member) { instance_double StaffMember, :pom_staff_member, staff_id: staff_id }
  let(:upcoming_handover_allocated_offenders) do
    double(:upcoming_handover_allocated_offenders)
  end
  let(:handover_cases) { instance_double HandoverCasesList, :handover_cases }

  before do
    # TODO: this amount of stubbing to get the tests to run really tells us that our controller plumbing is not very
    #  well designed. We need to find ways to tidy it up, one strand at a time.
    allow(controller).to receive(:authenticate_user)
    allow(controller).to receive(:check_prison_access)
    allow(controller).to receive(:load_staff_member)
    allow(controller).to receive(:service_notifications)
    allow(controller).to receive(:load_roles)
    allow(controller).to receive(:ensure_pom)
    allow(controller).to receive(:active_prison_id).and_return(prison_code)
    controller.instance_variable_set(:@current_user, pom_staff_member)

    allow(HandoverCasesList).to receive(:new).with(staff_member: pom_staff_member).and_return(handover_cases)
  end

  shared_examples 'handover cases list page' do
    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has prison id' do
      expect(assigns(:prison_id)).to eq prison_code
    end

    it 'has handover cases list' do
      expect(assigns(:handover_cases)).to eq handover_cases
    end
  end

  describe 'upcoming handovers page' do
    before do
      get :upcoming, params: default_params
    end

    it_behaves_like 'handover cases list page'
  end
end
