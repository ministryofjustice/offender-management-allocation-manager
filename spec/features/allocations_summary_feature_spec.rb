require 'rails_helper'

feature 'allcations summary feature' do
  around do |example|
    travel_to Date.new(2018, 11, 10, 15) do
      example.run
    end
  end

  describe 'awaiting tiering' do
    it 'displays offenders awaiting tiering', vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/#awaiting_tiering'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting tiering')
    end
  end
end
