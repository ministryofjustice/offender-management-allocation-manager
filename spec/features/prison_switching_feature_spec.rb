require 'rails_helper'

feature 'Switching prisons' do
  it 'Shows the switcher if the user has more than one prison',
    vcr: { cassette_name: :prison_switching_feature_many_prisons_spec } do
    signin_user
    visit root_path

    expect(page).to have_css('h2', text: 'HMP Leeds')
  end

  it 'Shows the list of prisons I can switch to',
    vcr: { cassette_name: :prison_switching_feature_list_spec }do
    signin_user
    visit root_path

    click_link('Switch prison')

    expect(page).to have_css('a', text: 'HMP Leeds')
    expect(page).to have_css('a', text: 'HMP Risley')
  end

  it 'Changes my prison when I choose one',
    vcr: { cassette_name: :prison_switching_feature_change_prisons_spec }do
    signin_user
    visit root_path

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'Can remember where I was',
    vcr: { cassette_name: :prison_switching_feature_remember_prison_spec } do
    signin_user
    visit poms_path

    expect(page).to have_css('h2', text: 'HMP Leeds')

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).to have_current_path(poms_path)
    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'sends me to the dashboard if no referer',
    vcr: { cassette_name: :prison_switching_feature_redirect_dash_spec } do
    signin_user
    visit prisons_update_path(code: 'PVI')
    expect(page).to have_current_path(root_path)
  end
end
