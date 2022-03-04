require 'rails_helper'

feature 'Switching prisons' do
  before do
    create(:prison, code: 'RSI')
  end

  it 'Shows the switcher if the user has more than one prison',
     vcr: { cassette_name: 'prison_api/prison_switching_feature_many_prisons_spec' } do
    signin_spo_user(['LEI', 'RSI'])
    visit root_path

    expect(page).to have_css('h2', text: 'Leeds (HMP)')
  end

  it 'shows dashboard links if there is no referrer', vcr: { cassette_name: 'prison_api/nav_to_prison_switcher' } do
    signin_spo_user(['LEI', 'RSI'])

    visit root_path

    visit prison_prisons_path('LEI')

    expect(page).to have_css('a', text: 'Leeds (HMP)')
    expect(page).to have_css('a', text: 'Risley (HMP)')

    click_link('Risley (HMP)')

    expect(page).not_to have_content('Leeds (HMP)')
    expect(page).to have_content('Risley (HMP)')
  end

  it 'Shows the list of prisons I can switch to',
     vcr: { cassette_name: 'prison_api/prison_switching_feature_list_spec' } do
    signin_spo_user(['LEI', 'RSI'])
    visit root_path

    click_link('Change your location')

    expect(page).to have_css('a', text: 'Leeds (HMP)')
    expect(page).to have_css('a', text: 'Risley (HMP)')
  end

  it 'Changes my prison when I choose one',
     vcr: { cassette_name: 'prison_api/prison_switching_feature_change_prisons_spec' } do
    signin_spo_user(['LEI', 'RSI'])
    visit root_path

    click_link('Change your location')
    click_link('Risley (HMP)')

    expect(page).not_to have_content('Leeds (HMP)')
    expect(page).to have_content('Risley (HMP)')
  end

  it 'Can remember where I was',
     vcr: { cassette_name: 'prison_api/prison_switching_feature_remember_prison_spec' } do
    signin_spo_user(['LEI', 'RSI'])
    visit prison_poms_path('LEI')

    expect(page).to have_css('h2', text: 'Leeds (HMP)')

    click_link('Change your location')
    click_link('Risley (HMP)')

    expect(page).to have_current_path(prison_poms_path('RSI'))
    expect(page).not_to have_content('Leeds (HMP)')
    expect(page).to have_content('Risley (HMP)')
  end
end
