require 'rails_helper'

feature 'allocate a POM' do
  it 'shows the allocate a POM page', vcr: { cassette_name: :get_offender_details, match_requests_on: [:query] } do
    signin_user

    visit '/allocate_prison_offender_managers/G2911GD/edit'

    expect(page).to have_css('h1', text: 'Allocate a Prison Offender Manager')
    expect(page).not_to have_css('.govuk-breadcrumbs')
  end
end
