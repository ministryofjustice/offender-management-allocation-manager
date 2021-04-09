require 'rails_helper'

feature 'Search for offenders' do
  let(:prison) { 'LEI' }

  it 'Can search from the dashboard', vcr: { cassette_name: 'prison_api/dashboard_search_feature' } do
    signin_spo_user
    visit root_path

    expect(page).to have_text('Dashboard')
    fill_in 'q', with: 'Cal'
    click_on('search-button')

    expect(page).to have_current_path(search_prison_prisoners_path(prison), ignore_query: true)
    expect(page).to have_css('tbody tr', count: 6)
  end

  it 'Can search from the Allocations summary page', vcr: { cassette_name: 'prison_api/allocated_search_feature' } do
    signin_spo_user
    visit allocated_prison_prisoners_path(prison)

    expect(page).to have_text('See allocations')
    fill_in 'q', with: 'Fra'
    click_on('search-button')

    expect(page).to have_current_path(search_prison_prisoners_path(prison), ignore_query: true)
    expect(page).to have_css('tbody tr', count: 9)
  end

  it 'Can search from the Awaiting Allocation summary page', vcr: { cassette_name: 'prison_api/waiting_allocation_search_feature' } do
    signin_spo_user
    visit unallocated_prison_prisoners_path(prison)

    expect(page).to have_text('Make allocations')
    fill_in 'q', with: 'Tre'
    click_on('search-button')

    expect(page).to have_current_path(search_prison_prisoners_path(prison), ignore_query: true)
    expect(page).to have_css('tbody tr', count: 1)
  end

  it 'Can search from the Missing Information summary page', vcr: { cassette_name: 'prison_api/missing_info_search_feature' } do
    signin_spo_user
    visit  missing_information_prison_prisoners_path(prison)

    expect(page).to have_text('Make allocations')
    fill_in 'q', with: 'Ste'
    click_on('search-button')

    expect(page).to have_current_path(search_prison_prisoners_path(prison), ignore_query: true)
    expect(page).to have_css('tbody tr', count: 4)
  end
end
