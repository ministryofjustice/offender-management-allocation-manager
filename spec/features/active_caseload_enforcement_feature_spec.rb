# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Active caseload enforcement' do
  let(:pom) do
    build(
      :pom,
      firstName: 'Alice',
      lastName: 'Example',
      position: RecommendationService::PRISON_POM,
      staffId: 485_926
    )
  end

  before do
    create(:prison, code: 'LEI')
    create(:prison, code: 'RSI')

    signin_spo_user(%w[LEI RSI])
    stub_poms('LEI', [pom])
    stub_poms('RSI', [pom])
    stub_offenders_for_prison('LEI', [])

    stub_dps_header_footer
  end

  it 'redirects a different prison URL to the live active caseload dashboard', skip_active_caseload_check_stubbing: true do
    visit prison_dashboard_index_path('RSI')

    expect(page).to have_current_path(prison_dashboard_index_path('LEI'))
    expect(page).to have_content('Leeds (HMP) selected')
  end
end
