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
    allow_any_instance_of(SsoIdentity).to receive(:sso_identity).and_return(
      'username' => 'PK000223',
      'caseload' => ['LEI'],
      'active_caseload' => 'LEI'
    )

    signin_user('PK000223')
    visit '/contact_us'

    expect(page.find("#prison").value).to eq('HMP Leeds')
    expect(page.find("#name").value).to eq('Kath Pobee-Norris')

    expect(page).to have_button('Submit')
  end
end
