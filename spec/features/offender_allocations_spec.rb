require 'rails_helper'

feature 'allocate a POM' do
  it 'shows the allocate a POM page' do
    signin_user

    visit '/allocate_prison_offender_managers'

    expect(page).to have_css('h1', text: 'Allocate a Prison Offender Manager')
  end
end
