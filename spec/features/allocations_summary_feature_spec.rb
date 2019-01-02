require 'rails_helper'

feature 'allocations summary feature' do
  around do |example|
    travel_to Time.zone.local(2019, 1, 2, 16, 0) do
      example.run
    end
  end

  describe 'awaiting allocations table' do
    it 'displays offenders awaiting tiering', vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/missing-information'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting tiering')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'renders allocation offenders at index', vcr: { cassette_name: :allocated_offenders } do
      signin_user
      visit 'allocations'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'displays offenders already allocated', vcr: { cassette_name: :allocated_offenders } do
      signin_user

      visit 'allocations/allocated'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'displays offenders pending allocation', vcr: { cassette_name: :awaiting_allocation_offenders } do
      signin_user

      visit 'allocations/awaiting'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting allocation')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end
  end
end
