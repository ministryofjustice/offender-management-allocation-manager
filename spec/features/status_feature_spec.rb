require 'rails_helper'

feature 'get status' do
  it 'returns a status message', vcr: { cassette_name: :get_status_feature, record: :new_episodes, re_record_interval: 1.hour } do
    hmpps_sso_response = {
      'info' => {
        'username' => 'Fred'
      }
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)

    visit '/'

    expect(page).to have_css('.status', text: 'ok')
    expect(page).to have_css('.postgres_version', text: 'PostgreSQL 10.5')
    expect(page).to have_css('.govuk-header__link', text: 'Fred')
  end
end
