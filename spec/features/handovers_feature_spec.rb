require 'ostruct'

RSpec.feature 'Handovers feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:user) { FactoryBot.build(:pom) }
  let(:default_params) do
    {
      prison_id: prison_code,
      new_handover: NEW_HANDOVER_TOKEN
    }
  end
  let(:offender_attrs) do
    erd = Faker::Date.forward
    {
      full_name: 'Surname1, Firstname1',
      last_name: 'Surname1',
      offender_no: 'X1111XX',
      tier: 'A',
      earliest_release: { type: 'TED', date: erd },
      earliest_release_date: erd,
      case_allocation: 'HDCED'
    }
  end

  before do
    stub_auth_token
    stub_user(staff_id: user.staff_id)

    signin_pom_user([prison_code])
    stub_poms(prison_code, [user])
  end

  describe 'upcoming handovers' do
    it 'works' do
      allow_any_instance_of(StaffMember).to receive(:unreleased_allocations).and_return(
        [
          instance_double(AllocatedOffender, offender_attrs.merge(allocated_com_name: nil))
        ]
      )
      date = FactoryBot.create :calculated_handover_date,
                               offender: FactoryBot.create(:offender, nomis_offender_id: 'X1111XX')
      allow(CalculatedHandoverDate).to receive(:by_upcoming_handover).and_return [date]

      visit upcoming_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Upcoming handovers'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
      end
    end
  end

  describe 'in progress handovers' do
    it 'works' do
      allow_any_instance_of(StaffMember).to receive(:unreleased_allocations).and_return(
        [
          instance_double(AllocatedOffender, offender_attrs.merge(allocated_com_name: 'Mr COM',
                                                                  allocated_com_email: 'mr-com@example.org'))
        ]
      )
      date = FactoryBot.create :calculated_handover_date, :between_com_allocated_and_responsible_dates,
                               offender: FactoryBot.create(:offender, nomis_offender_id: 'X1111XX')
      allow(CalculatedHandoverDate).to receive(:by_handover_in_progress).and_return [date]

      visit in_progress_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Handovers in progress'
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
        expect(page).to have_text 'Mr COM mr-com@example.org'
      end
    end
  end
end
