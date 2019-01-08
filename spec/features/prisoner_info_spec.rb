require 'rails_helper'

feature 'View a prisoner profile page' do
  it 'shows the prisoner information' do
    signin_user

    visit '/prisoners/1'

    expect(page).to have_css('h2', text: 'Surname, Forename')
  end
end
