require 'rails_helper'

feature 'allocations summary feature' do
  describe 'awaiting allocations table' do
    it 'displays offenders awaiting information', :raven_intercept_exception, vcr: { cassette_name: :awaiting_information_feature } do
      signin_user

      visit 'allocations#awaiting-information'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting information')
      within('#awaiting-information') do
        expect(page).to have_css('.pagination ul.links li', count: 7)
      end
    end

    it 'displays offenders pending allocation', :raven_intercept_exception, vcr: { cassette_name: :awaiting_allocation_feature } do
      signin_user

      visit 'allocations#awaiting-allocation'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting allocation')
      within('#awaiting-allocation') do
        expect(page).to have_css('.pagination ul.links li', count: 2)
      end
    end

    it 'displays offenders already allocated', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_feature } do
      signin_user

      visit 'allocations#allocated'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      within('#allocated') do
        expect(page).to have_css('.pagination ul.links li', count: 2)
      end
    end


  end

  describe 'paging' do
    it 'shows pages for allocation', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_paged_feature, match_requests_on: [:query] } do
      signin_user

      visit allocations_path
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^1$/)

      visit allocations_path(page: 2)
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^2$/)

      visit allocations_path(page: 3)
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^3$/)

      visit allocations_path(page: 4)
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^4$/)

      visit allocations_path(page: 117)
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^117$/)
      expect(page).not_to have_link(/^118$/)
    end
  end
end
