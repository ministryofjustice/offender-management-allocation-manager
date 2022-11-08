RSpec.feature 'Handover progress checklist feature:' do
  let!(:prison) { FactoryBot.create(:prison) }
  let(:prison_code) { prison.code }
  let(:user) { FactoryBot.build(:pom) }
  let(:default_params) { { nomis_offender_id: 'ABC123D', prison_id: prison_code } }

  before do
    stub_auth_token
    stub_user(staff_id: user.staff_id)

    signin_pom_user([prison_code])
    stub_poms(prison_code, [user])
  end

  it 'works' do
    visit prison_edit_handover_progress_checklist_path(default_params)
    expect(page.status_code).to eq 200
  end
end
