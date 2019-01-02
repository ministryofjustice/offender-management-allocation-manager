require 'rails_helper'

feature 'allcations summary feature' do
  around do |example|
    travel_to Date.new(2018, 12, 17, 11) do
      example.run
    end
  end

  describe 'awaiting allocations table' do
    it 'renders allocation offenders at index', :expect_exception, vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user
      visit 'allocations'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'displays offenders awaiting tiering', :expect_exception, vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/waiting'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting tiering')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'displays offenders already allocated', :expect_exception, vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/allocated'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Allocated')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end

    it 'displays offenders pending allocation', :expect_exception, vcr: { cassette_name: :awaiting_tiering_feature } do
      signin_user

      visit 'allocations/pending'

      expect(page).to have_css('.govuk-tabs__tab', text: 'Awaiting allocation')
      expect(page).to have_css('.govuk-breadcrumbs')
      expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
    end
  end
end
