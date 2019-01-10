require 'rails_helper'

feature 'allocations summary feature' do
  around do |example|
    travel_to Time.zone.local(2019, 1, 9, 12, 00) do
      example.run
    end
  end

  describe 'awaiting allocations table' do
    it 'displays offenders awaiting tiering', :raven_intercept_exception, vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/missing-information'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting tiering')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
      expect(page).to have_css('.pagination ul.links li', count: 7)
    end

    it 'renders allocation offenders at index', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders } do
      signin_user
      visit 'allocations'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
      expect(page).to have_css('.pagination')
      expect(page).to have_css('.pagination ul.links li', count: 7)
    end

    it 'displays offenders already allocated', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders } do
      signin_user

      visit 'allocations/allocated'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
      expect(page).to have_css('.pagination ul.links li', count: 7)
    end

    it 'displays offenders pending allocation', :raven_intercept_exception, vcr: { cassette_name: :awaiting_allocation_offenders } do
      signin_user

      visit 'allocations/awaiting'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting allocation')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
      expect(page).to have_css('.pagination ul.links li', count: 7)
    end
  end

  describe 'paging' do
    it 'shows pages for allocation', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_paged, match_requests_on: [:query] } do
      signin_user

      visit allocations_allocated_path
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link(/^1$/)

      visit allocations_allocated_path(page: 2)
      expect(page).to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^2$/)

      visit allocations_allocated_path(page: 3)
      expect(page).to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^3$/)

      visit allocations_allocated_path(page: 4)
      expect(page).to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^4$/)

      visit allocations_allocated_path(page: 117)
      expect(page).not_to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link(/^117$/)
      expect(page).not_to have_link(/^118$/)
    end
  end
end
