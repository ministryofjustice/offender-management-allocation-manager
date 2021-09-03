require 'rails_helper'

feature 'feedback' do
  let(:feedback_link) { 'https://eu.surveymonkey.com/r/3BJ9M5K' }

  it 'provides a link to the feedback form', vcr: { cassette_name: 'prison_api/feedback_link' } do
    signin_spo_user

    visit '/'

    footer = page.find(:css, '.govuk-footer')
    within footer do
      expect(page).to have_link('Feedback', href: feedback_link)
    end
  end
end
