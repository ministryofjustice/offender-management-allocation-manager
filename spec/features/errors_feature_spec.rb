require 'rails_helper'

feature 'Errors' do
  before do
    # So we can simulate what would happen on production
    allow(
      Rails.application.config
    ).to receive(:consider_all_requests_local).and_return(false)
  end

  context 'when signed in' do
    it "handles missing pages (nonexistent path)" do
      visit "/foobar"
      expect(page).to have_http_status(:not_found)
      expect(page).to have_content('Page not found')
    end

    it "handles missing pages" do
      visit "/404"
      expect(page).to have_http_status(:not_found)
      expect(page).to have_content('Page not found')
    end

    it "handles unauthorized access" do
      visit "/401"
      expect(page).to have_http_status(:unauthorized)
      expect(page).to have_content('You do not have permission to access this')
    end

    it "handles errors" do
      visit "/500"
      expect(page).to have_http_status(:error)
      expect(page).to have_content('Sorry, there is a problem with the POM caseload service')
    end
  end

  context 'when signed out' do
    before do
      allow(SsoIdentity).to receive(:new).and_return(nil)
    end

    it "handles missing pages (nonexistent path)" do
      visit "/foobar"
      expect(page).to have_http_status(:not_found)
      expect(page).to have_content('Page not found')
    end

    it "handles missing pages" do
      visit "/404"
      expect(page).to have_http_status(:not_found)
      expect(page).to have_content('Page not found')
    end

    it "handles unauthorized access" do
      visit "/401"
      expect(page).to have_http_status(:unauthorized)
      expect(page).to have_content('You do not have permission to access this')
    end

    it "handles errors" do
      visit "/500"
      expect(page).to have_http_status(:error)
      expect(page).to have_content('Sorry, there is a problem with the POM caseload service')
    end
  end
end
