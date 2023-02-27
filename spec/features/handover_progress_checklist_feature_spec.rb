RSpec.feature 'Handover progress checklist feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
  let(:user) { FactoryBot.build(:pom) }
  let(:offender) { stub_mpc_offender(offender_no: nomis_offender_id) }
  let(:default_params) { { nomis_offender_id: nomis_offender_id, prison_id: prison_code } }

  before do
    FactoryBot.create :offender, :nps, nomis_offender_id: nomis_offender_id
    allow(OffenderService).to receive(:get_offender).and_return nil
    offender # instantiate and stub

    stub_auth_token
    stub_user(staff_id: user.staff_id)
    allow_any_instance_of(StaffMember).to receive(:has_allocation?).and_return(true)

    signin_pom_user([prison_code])
    stub_poms(prison_code, [user])

    allow_any_instance_of(StaffMember).to receive(:unreleased_allocations).and_return([])
  end

  it 'allows completing the checklist' do
    expect(HandoverProgressChecklist.count).to eq 0
    visit prison_edit_handover_progress_checklist_path(default_params)
    expect(page.status_code).to eq 200
    click_on 'Save tasks'
    expect(page.status_code).to eq 200
    expect(HandoverProgressChecklist.find_by(nomis_offender_id: nomis_offender_id).contacted_com).to eq false
  end
end
