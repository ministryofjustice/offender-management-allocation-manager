require 'rails_helper'

RSpec.feature 'fetch status' do
  it 'returns a status message' do
    visit '/'

    expect(page).to have_selector('h1', text: 'Offender Management Allocation API Status')
  end
end
