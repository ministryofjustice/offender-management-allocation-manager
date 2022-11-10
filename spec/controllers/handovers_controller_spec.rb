RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { 'DBG' }
  let(:prison) { instance_double Prison, :prison, code: prison_code }
  let(:default_params) { { prison_id: prison_code } }
  let(:staff_id) { 456_987 }
  let(:pom_staff_member) { instance_double StaffMember, :pom_staff_member, staff_id: staff_id }
  let(:upcoming_handover_allocated_offenders) do
    double(:upcoming_handover_allocated_offenders)
  end
  let(:handover_cases) { instance_double HandoverCasesList, :handover_cases }

  before do
    stub_high_level_pom_auth(prison: prison, pom_staff_member: pom_staff_member)
    allow(HandoverCasesList).to receive(:new).with(staff_member: pom_staff_member).and_return(handover_cases)

    session[:new_handovers_ui] = true
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
