require 'rails_helper'

feature 'Getting help' do
  context 'when viewing the help page' do
    it "can show the help page", vcr: { cassette_name: :getting_help_text } do
      visit "help"
      expect(page).to have_content('Help')
      expect(page).to have_link('Back')
      expect(page).to have_link('Read guidance', href: 'guidance')
      expect(page).to have_link('moic@digital.justice.gov.uk')
    end

    it "clicks back to an existing previous page", vcr: { cassette_name: :help_back_to_previous_page } do
      visit "guidance"
      click_link("Help")
      click_link("Back")
      expect(page).to have_css('.govuk-heading-l', text: 'Get started with the allocations service')
    end

    it "clicks back to root path if no previous page exists", vcr: { cassette_name: :help_root_path } do
      signin_user
      visit "help"
      click_link("Back")
      expect(page).to have_content('HMPPS Allocate to a Prison Offender Manager')
    end
  end

  context 'when viewing the contact page' do
    it "can show the contact page", vcr: { cassette_name: :getting_help_contact } do
      visit "contact"
      expect(page).to have_content('Contact')
    end
  end
end
