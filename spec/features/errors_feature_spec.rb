require 'rails_helper'

feature 'Errors' do
  it "handles missing pages", vcr: { cassette_name: 'prison_api/errors_feature_missing' } do
    visit "/404"
    expect(page).to have_http_status(:not_found)
    expect(page).to have_content('Page not found')
  end

  it "handles unauthorized access", vcr: { cassette_name: 'prison_api/errors_feature_unauthorized' } do
    visit "/401"
    expect(page).to have_http_status(:unauthorized)
    expect(page).to have_content('You do not have permission to access this')
  end

  it "handles errors", vcr: { cassette_name: 'prison_api/errors_feature_handles_500' } do
    visit "/500"
    expect(page).to have_http_status(:error)
    expect(page).to have_content('Sorry, there is a problem with the POM caseload service')
  end
end
