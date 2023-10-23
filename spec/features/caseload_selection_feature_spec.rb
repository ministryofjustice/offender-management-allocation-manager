RSpec.feature 'Caseload selection:' do
  before do
    FactoryBot.create(:prison, code: 'RSI')
  end

  it 'does not allow you to work on a different prison than your HMPPS-wide active caseload setting',
     vcr: { cassette_name: 'caseload_selection_cannot_work_on_different_from_active' },
     skip_active_caseload_check_stubbing: true do
    signin_spo_user(['LEI', 'RSI'])
    allow(HmppsApi::ActiveCaseloadApi).to receive(:current_user_active_caseload).and_return('LEI')
    visit prison_dashboard_index_path('RSI')
    expect(page).to have_content I18n.t('views.navigation.enforce_active_caseload')
  end
end
