require 'rails_helper'

feature 'allcations summary feature' do

  describe 'awaiting tiering' do
    it 'displays offenders awaiting tiering' do
      signin_user

      visit 'allocations/#awaiting_tiering'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting tiering')
    end
  end
end


