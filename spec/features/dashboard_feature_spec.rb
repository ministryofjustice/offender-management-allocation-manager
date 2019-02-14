require 'rails_helper'

feature 'get dashboard' do
  it 'shows the status page', vcr: { cassette_name: :dashboard_feature } do
    signin_user

    visit '/'

    expect(page).to have_css('.dashboard-row', count: 3)
    expect(page).to have_link('Allocated prisoners', href: allocations_path(anchor: 'allocated'))
    expect(page).to have_link('Awaiting allocation', href: allocations_path(anchor: 'awaiting-allocation'))
    expect(page).to have_link('Awaiting information', href: allocations_path(anchor: 'awaiting-information'))
  end
end
