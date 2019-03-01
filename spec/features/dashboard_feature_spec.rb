require 'rails_helper'

feature 'get dashboard' do
  it 'shows the status page', vcr: { cassette_name: :dashboard_feature } do
    signin_user('PK000223')

    visit '/'

    expect(page).to have_css('.dashboard-row', count: 3)
    expect(page).to have_link('See all allocated prisoners', href: summary_allocated_path)
    expect(page).to have_link('Make new allocations', href: summary_unallocated_path)
    expect(page).to have_link('Update case information', href: summary_pending_path)
  end
end
