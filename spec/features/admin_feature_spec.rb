require 'rails_helper'

feature 'Admin' do
  # TODO: This results in an infinite redirect
  xscenario 'unauthorised' do
    visit('/admin')
    expect(page).to have_http_status(:unauthorized)
  end

  context 'when pom' do
    before do
      signin_pom_user
    end

    it 'is unauthorised' do
      visit('/admin')
      expect(page).to have_http_status(:unauthorized)
    end
  end

  context 'when spo' do
    before do
      signin_spo_user
    end

    it 'displays the dashboard' do
      visit('/admin')
      expect(page).to have_http_status(:success)
    end
  end
end
