require 'rails_helper'

feature 'get status' do
  it 'returns a status message', vcr: { cassette_name: :status_feature } do
    signin_user

    visit '/status'

    expect(page).to have_css('.status', text: 'ok')
    expect(page).to have_css('.postgres_version', text: 'PostgreSQL 10.5')
    expect(page).to have_css('.govuk-header__link', text: 'Fred')
  end
end
