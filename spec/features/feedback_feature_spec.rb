require 'rails_helper'

feature 'feedback' do
  it 'provides a link to the feedback form', vcr: { cassette_name: :feedback_link } do
    signin_user('PK000223')

    visit '/'

    feedback_link = 'https://www.research.net/r/MM8TNLW'

    footer = page.find(:css, '.govuk-footer')
    within footer do
      expect(page).to have_link('Feedback', href: feedback_link)
    end
  end
end
