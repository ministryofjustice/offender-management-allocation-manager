require 'ostruct'

RSpec.feature 'Handovers feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:user) { FactoryBot.build(:pom) }
  let(:default_params) do
    {
      prison_id: prison_code,
      new_handover: 'b00a391b-c672-4c8c-bac8-801bfddaf44d'
    }
  end

  describe 'upcoming handovers' do
    it 'works' do
      allow_any_instance_of(StaffMember).to receive(:allocations).and_return(
        [
          instance_double(AllocatedOffender,
                          full_name: 'Surname1, Firstname1',
                          last_name: 'Surname1',
                          offender_no: 'X1111XX',
                          tier: 'A',
                          earliest_release: { type: 'TED', date: Date.new(2022, 1, 30) },
                          allocated_com_name: nil,
                          case_allocation: 'HDCED')
        ]
      )
      date = FactoryBot.create :calculated_handover_date,
                               offender: FactoryBot.create(:offender, nomis_offender_id: 'X1111XX')
      allow(CalculatedHandoverDate).to receive(:by_upcoming_handover).and_return [date]

      stub_auth_token
      stub_user(staff_id: user.staff_id)

      signin_pom_user([prison_code])
      stub_poms(prison_code, [user])

      visit upcoming_prison_handovers_path(default_params)

      aggregate_failures do
        expect(page.status_code).to eq 200
        expect(page).to have_text 'Surname1, Firstname1 X1111XX'
      end
    end
  end
end
