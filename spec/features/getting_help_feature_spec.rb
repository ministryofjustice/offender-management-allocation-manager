require 'rails_helper'

feature 'Getting help' do
  it "can show the help page", vcr: { cassette_name: :getting_help_text } do
    visit "help"
    expect(page).to have_content('Help')
  end

  it "can show the contact page", vcr: { cassette_name: :getting_help_contact } do
    visit "contact"
    expect(page).to have_content('Contact')
  end
end
