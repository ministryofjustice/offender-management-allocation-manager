require 'rails_helper'

feature 'Switching prisons' do
  it 'Shows the switcher if the user has more than one prison',
     vcr: { cassette_name: :prison_switching_feature_many_prisons_spec } do
    signin_spo_user
    visit root_path

    expect(page).to have_css('h2', text: 'HMP Leeds')
  end

  it 'shows dashboard links if there is no referrer', vcr: { cassette_name: :nav_to_prison_switcher } do
    signin_spo_user

    visit root_path

    visit prison_prisons_path('LEI')

    expect(page).to have_css('a', text: 'HMP Leeds')
    expect(page).to have_css('a', text: 'HMP Risley')

    click_link('HMP Risley')

    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'Shows the list of prisons I can switch to',
     vcr: { cassette_name: :prison_switching_feature_list_spec }do
    signin_spo_user
    visit root_path

    click_link('Switch prison')

    expect(page).to have_css('a', text: 'HMP Leeds')
    expect(page).to have_css('a', text: 'HMP Risley')
  end

  it 'Changes my prison when I choose one',
     vcr: { cassette_name: :prison_switching_feature_change_prisons_spec }do
    signin_spo_user
    visit root_path

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'Can remember where I was',
     vcr: { cassette_name: :prison_switching_feature_remember_prison_spec } do
    signin_spo_user
    visit prison_poms_path('LEI')

    expect(page).to have_css('h2', text: 'HMP Leeds')

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).to have_current_path(prison_poms_path('RSI'))
    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end
end
