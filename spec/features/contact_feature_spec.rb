require 'rails_helper'

feature 'get contact' do
  it 'shows the contact form page', vcr: { cassette_name: :contact_form } do
    signin_user('PK000223')

    visit '/contact'

    expect(page).to have_css('.govuk-label', text: 'You can use this form to ask a question, report a problem or suggest an improvement.')
    expect(page).to have_css('#more-detail-hint', text: 'Do not include personal or financial information, like your National Insurance number or credit card details.')
    expect(page).to have_css('.govuk-textarea')
    expect(page).to have_button('Submit')
  end

  it 'shows an error when empty form submitted', vcr: { cassette_name: :contact_form_empty_submit } do
    signin_user('PK000223')

    visit '/contact'

    click_button('Submit')

    expect(page).to have_css('.govuk-error-message', text: "The text box can't be blank")
  end
end
