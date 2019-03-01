require 'rails_helper'

feature 'summary summary feature' do
  describe 'awaiting summary table' do
    it 'displays offenders awaiting information', :raven_intercept_exception, vcr: { cassette_name: :awaiting_information_feature } do
      signin_user

      visit summary_pending_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
      expect(page).to have_css('.pagination ul.links li', count: 7)
    end

    it 'displays offenders pending allocation', :raven_intercept_exception, vcr: { cassette_name: :awaiting_allocation_feature } do
      signin_user

      visit summary_unallocated_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
      expect(page).to have_css('.pagination ul.links li', count: 0)
    end

    it 'displays offenders already allocated', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_feature } do
      signin_user

      visit summary_allocated_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('See allocations')
      expect(page).to have_css('.pagination ul.links li', count: 0)
    end
  end

  describe 'paging' do
    it 'shows pages for allocation', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_paged_feature, match_requests_on: [:query] } do
      signin_user

      visit summary_pending_path
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^1$/)

      visit summary_pending_path(page: 2)
      expect(page).to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^2$/)

      visit summary_pending_path(page: 117)
      expect(page).not_to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^117$/)
      expect(page).not_to have_link(/^118$/)
    end
  end
end
