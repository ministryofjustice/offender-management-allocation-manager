require 'rails_helper'

feature 'Getting help' do
  it 'shows an empty contact form when no user is signed in' do
    visit '/help'

    expect(page).to have_css('.govuk-body', text: 'Complete this form for technical help')
    expect(page).to have_css('.govuk-label', text: "Full name")
    expect(page).to have_css('.govuk-textarea')
    expect(page).to have_button('Submit')
  end

  it 'shows a pre-filled contact form when a user is signed in', :raven_intercept_exception, vcr: { cassette_name: :help_logged_in } do
    allow_any_instance_of(SSOIdentity).to receive(:sso_identity).and_return(
      'username' => 'PK000223',
      'caseload' => ['LEI'],
      'active_caseload' => 'LEI'
                                                                            )

    signin_user('PK000223')
    visit '/help'

    expect(page.find("#prison").value).to eq('HMP Leeds')

    expect(page).to have_button('Submit')
  end

  it 'shows an error when empty form submitted' do
    visit '/help'

    click_button('Submit')

    expect(page).to have_content('There is a problem')
  end

  it 'redirects a signed in user to the dashboard', :raven_intercept_exception, vcr: { cassette_name: :help_logged_in_submit_form } do
    allow(Rails.configuration).to receive(:zendesk_enabled).and_return(false)
    allow_any_instance_of(SSOIdentity).to receive(:sso_identity).and_return(
      'username' => 'PK000223',
      'caseload' => ['LEI'],
      'active_caseload' => 'LEI'
                                                                            )

    signin_user('PK000223')
    visit '/help'

    fill_in 'job_type', with: 'SPO'
    fill_in 'message', with: 'This is a test'
    click_button('Submit')

    expect(page).to have_css('.notification', text: 'Your form has been submitted')
    expect(page).to have_current_path prison_dashboard_index_path('LEI')
  end

  it 'redirects a logged out user to the help page' do
    visit '/help'

    fill_in 'name', with: 'Kath'
    fill_in 'email_address', with: 'Kath@example.com'
    fill_in 'prison', with: 'Leeds'
    fill_in 'job_type', with: 'SPO'
    fill_in 'message', with: 'This is a test'
    click_on('Submit')

    expect(page).to have_css('.notification', text: 'Your form has been submitted')
    expect(page).to have_current_path help_path
  end
end
