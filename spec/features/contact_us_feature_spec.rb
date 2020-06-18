require 'rails_helper'

feature 'Getting help' do
  it 'shows an empty contact form when no user is signed in' do
    visit '/contact_us'

    expect(page).to have_css('.govuk-body', text: 'Complete this form for technical help')
    expect(page).to have_css('.govuk-label', text: "Full name")
    expect(page).to have_css('.govuk-textarea')
    expect(page).to have_button('Submit')
  end

  it 'shows a pre-filled contact form when a user is signed in', :raven_intercept_exception, vcr: { cassette_name: :help_logged_in } do
    signin_user('MOIC_POM')
    visit '/'
    click_link 'Contact us'

    expect(page.find("#prison").value).to eq('HMP Leeds')
    expect(page.find("#name").value).to eq('Moic Pom')

    expect(page).to have_button('Submit')
  end
end
