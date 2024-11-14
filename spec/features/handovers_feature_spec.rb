RSpec.feature 'Handovers feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:user) { FactoryBot.build(:pom) }
  let(:default_params) { { prison_id: prison_code } }
  let(:offender_attrs) do
    {
      full_name: 'Surname1, Firstname1',
      last_name: 'Surname1',
      offender_no: 'X1111XX',
      tier: 'A',
      handover_progress_task_completion_data: {},
      allocated_com_email: nil,
      allocated_com_name: nil,
      ldu_name: nil,
      ldu_email_address: nil,
      handover_progress_complete?: false,
      case_information: double(enhanced_handover?: false),
      handover_type: 'enhanced',
    }
  end
  let(:offender) { sneaky_instance_double AllocatedOffender, **offender_attrs }
  let(:handover_cases) do
    sneaky_instance_double(Handover::CategorisedHandoverCases, upcoming: [],
                                                               in_progress: [],
                                                               overdue_tasks: [],
                                                               com_allocation_overdue: [])
  end
  let(:handover_case) do
    instance_double Handover::HandoverCase,
                    earliest_release_for_handover: NamedDate[nil, nil],
                    offender: offender,
                    handover_date: Faker::Date.forward,
                    com_allocation_days_overdue: 10
  end

  before do
    stub_auth_token
    stub_user(staff_id: user.staff_id)
    signin_pom_user([prison_code])
    stub_poms(prison_code, [user])

    allow(StaffMember).to receive(:new)
      .with(prison, user.staffId)
      .and_return(instance_double(StaffMember, unreleased_allocations: []).as_null_object)
    allow(Handover::CategorisedHandoverCases).to receive(:new).and_return(handover_cases)
  end

  describe 'upcoming handovers' do
    it 'renders correctly' do
      allow(handover_cases).to receive(:upcoming).and_return([handover_case])
      visit upcoming_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Upcoming handovers'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
      end
    end
  end

  describe 'in progress handovers' do
    it 'renders correctly' do
      allow(offender).to receive(:allocated_com_name).and_return('Mr COM')
      allow(offender).to receive(:allocated_com_email).and_return('mr-com@example.org')
      allow(handover_cases).to receive(:in_progress)
                                 .and_return([handover_case])
      visit in_progress_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Handovers in progress'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
        expect(page).to have_text 'Mr COM mr-com@example.org'
      end
    end
  end

  describe 'overdue tasks' do
    it 'renders correctly' do
      allow(handover_cases).to receive(:overdue_tasks)
                                 .and_return([handover_case])
      visit overdue_tasks_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Overdue tasks'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
      end
    end
  end

  describe 'COM allocation overdue handovers page' do
    it 'renders correctly' do
      allow(handover_cases).to receive(:com_allocation_overdue)
                                 .and_return([handover_case])
      visit com_allocation_overdue_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Upcoming handovers'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
        expect(page).to have_text 'Days overdue'
        expect(page).to have_text 'LDU details'
      end
    end
  end
end
