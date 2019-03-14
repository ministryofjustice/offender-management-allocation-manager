require 'rails_helper'

feature 'Search for offenders' do
  it 'Can search from the dashboard', vcr: { cassette_name: :search_feature } do
    signin_user
    visit root_path

    expect(page).to have_text('Dashboard')
    fill_in 'q', with: 'Cal'
    click_on('search-button')

    expect(page).to have_current_path(search_path, ignore_query: true)
    expect(page).to have_css('tbody tr', count: 4)
  end
end
