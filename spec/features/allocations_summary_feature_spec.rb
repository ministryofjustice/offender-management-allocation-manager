require 'rails_helper'

feature 'summary summary feature' do
  describe 'awaiting summary table' do
    it 'redirects correctly', :raven_intercept_exception, vcr: { cassette_name: :redirect_summary_index_feature } do
      signin_user

      visit summary_path
      expect(page).to have_current_path summary_allocated_path
    end

    it 'displays offenders awaiting information', :raven_intercept_exception, vcr: { cassette_name: :awaiting_information_feature } do
      signin_user

      visit summary_pending_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
      expect(page).to have_css('.pagination ul.links li', count: 5)
    end

    it 'handles sorting params', :raven_intercept_exception, vcr: { cassette_name: :summary_sorting_feature } do
      signin_user

      get_ids = lambda {
        all('tbody tr td').map(&:text).select { |c|
          /[A-Z][0-9.][0-9.][0-9.][0-9.][A-Z][A-Z]/.match(c)
        }
      }

      visit summary_pending_path(sort: 'last_name')  # Default direction is asc.
      asc_cells = get_ids.call

      visit summary_pending_path(sort: 'last_name desc')
      desc_cells = get_ids.call

      expect(asc_cells).not_to match_array(desc_cells)
    end

    it 'displays offenders pending allocation', :raven_intercept_exception, vcr: { cassette_name: :awaiting_allocation_feature } do
      signin_user

      visit summary_unallocated_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
      expect(page).to have_css('.pagination ul.links li', count: 2)
    end

    it 'displays offenders already allocated', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_feature } do
      signin_user

      visit summary_allocated_path

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('See allocations')
      expect(page).to have_css('.pagination ul.links li', count: 2)
    end
  end

  describe 'paging' do
    it 'shows pages for allocation', :raven_intercept_exception, vcr: { cassette_name: :allocated_offenders_paged_feature } do
      signin_user

      visit summary_pending_path
      expect(page).to have_link('Next »')
      expect(page).not_to have_link('« Previous')
      expect(page).not_to have_link('1', exact: true)

      visit summary_pending_path(page: 2)
      expect(page).to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link('2', exact: true)

      visit summary_pending_path(page: 117)
      expect(page).not_to have_link('Next »')
      expect(page).to have_link('« Previous')
      expect(page).not_to have_link('117', exact: true)
      expect(page).not_to have_link('118', exact: true)
    end
  end
end
