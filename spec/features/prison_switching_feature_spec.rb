require 'rails_helper'

feature 'Switching prisons', vcr: { cassette_name: :prison_switching_feature_spec } do
  it 'Shows the switcher if the user has more than one prison' do
    signin_user
    visit root_path

    expect(page).to have_css('h2', text: 'HMP Leeds')
  end

  it 'Shows the list of prisons I can switch to' do
    signin_user
    visit root_path

    click_link('Switch prison')

    expect(page).to have_css('a', text: 'HMP Leeds')
    expect(page).to have_css('a', text: 'HMP Risley')
  end

  it 'Changes my prison when I choose one' do
    signin_user
    visit root_path

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'Can remember where I was' do
    signin_user
    visit poms_path

    expect(page).to have_css('h2', text: 'HMP Leeds')

    click_link('Switch prison')
    click_link('HMP Risley')

    expect(page).to have_current_path(poms_path)
    expect(page).not_to have_content('HMP Leeds')
    expect(page).to have_content('HMP Risley')
  end

  it 'sends me to the dashboard if no referer' do
    signin_user
    visit prisons_update_path(code: 'RIS')
    expect(page).to have_current_path(root_path)
  end
end
