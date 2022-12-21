RSpec.feature 'Handovers feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:user) { FactoryBot.build(:pom) }
  let(:default_params) { { prison_id: prison_code } }
  let(:offender_attrs) do
    erd = Faker::Date.forward
    {
      full_name: 'Surname1, Firstname1',
      last_name: 'Surname1',
      offender_no: 'X1111XX',
      tier: 'A',
      earliest_release: { type: 'TED', date: erd },
      earliest_release_date: erd,
      case_allocation: 'HDCED',
      handover_progress_task_completion_data: {},
      allocated_com_email: nil,
      allocated_com_name: nil,
      com_responsible_date: Faker::Date.backward,
      ldu_name: nil,
      ldu_email_address: nil,
    }
  end
  let(:offender) { instance_double AllocatedOffender, offender_attrs }
  let(:calc_handover_date) do
    instance_double CalculatedHandoverDate, :calc_handover_date, handover_date: Faker::Date.forward
  end
  let(:handover_cases_list) do
    instance_double(HandoverCasesList, :handover_cases_list, upcoming: [],
                                                             in_progress: [],
                                                             overdue_tasks: [],
                                                             com_allocation_overdue: [])
  end

  before do
    activate_new_handovers_ui

    stub_auth_token
    stub_user(staff_id: user.staff_id)
    signin_pom_user([prison_code])
    stub_poms(prison_code, [user])

    allow(HandoverCasesList).to receive(:new).and_return(handover_cases_list)
  end

  describe 'upcoming handovers' do
    it 'renders correctly' do
      allow(handover_cases_list).to receive(:upcoming).and_return([[calc_handover_date, offender]])
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
      allow(handover_cases_list).to receive(:in_progress).and_return([[calc_handover_date, offender]])
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
      allow(handover_cases_list).to receive(:overdue_tasks).and_return([[calc_handover_date, offender]])
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
      allow(handover_cases_list).to receive(:com_allocation_overdue).and_return([[calc_handover_date, offender]])
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
