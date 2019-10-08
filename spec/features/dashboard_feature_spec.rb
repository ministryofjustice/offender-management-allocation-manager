require 'rails_helper'

feature 'get dashboard' do
  it 'shows the status page', vcr: { cassette_name: :dashboard_feature } do
    signin_user('PK000223')

    visit '/'

    expect(page).to have_current_path(prison_dashboard_index_url('LEI'))

    expect(page).to have_css('.dashboard-row', count: 3)
    expect(page).to have_link('See all allocated prisoners', href: prison_summary_allocated_path('LEI'))
    expect(page).to have_link('Make new allocations', href: prison_summary_unallocated_path('LEI'))
    expect(page).to have_link('Update case information', href: prison_summary_pending_path('LEI'))
  end

  it 'shows the status page with direct access', vcr: { cassette_name: :dashboard_direct_feature } do
    signin_user('PK000223')

    visit '/prisons/LEI/dashboard'

    expect(page).to have_css('.dashboard-row', count: 3)
    expect(page).to have_link('See all allocated prisoners', href: prison_summary_allocated_path('LEI'))
    expect(page).to have_link('Make new allocations', href: prison_summary_unallocated_path('LEI'))
    expect(page).to have_link('Update case information', href: prison_summary_pending_path('LEI'))
  end

  it 'redirects to 401 if prison is invalid', vcr: { cassette_name: :dashboard_invalid_prison_feature } do
    signin_user('PK000223')

    visit '/prisons/LEIF/dashboard'
    expect(page).to have_current_path('/401')
  end
end
