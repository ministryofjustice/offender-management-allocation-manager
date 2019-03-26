require 'rails_helper'

feature 'Errors' do
  it "handles missing pages", vcr: { cassette_name: :errors_feature } do
    visit "/404"
    expect(page).to have_http_status(:not_found)
    expect(page).to have_content('Page not found')
  end

  it "handles unauthorized access", vcr: { cassette_name: :errors_feature } do
    visit "/401"
    expect(page).to have_http_status(:unauthorized)
    expect(page).to have_content('This service is currently available in only a few prisons')
  end

  it "handles errors", vcr: { cassette_name: :errors_feature } do
    visit "/500"
    expect(page).to have_http_status(:error)
    expect(page).to have_content('We are experiencing technical difficulties')
  end
end
