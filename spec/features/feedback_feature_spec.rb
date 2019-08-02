require 'rails_helper'

feature 'feedback' do
  it 'provides a link to the feedback form', vcr: { cassette_name: :feedback_link } do
    signin_user('PK000223')

    visit '/'

    expect(page).to have_link('feedback', href: 'https://www.research.net/r/MM8TNLW')
  end
end
