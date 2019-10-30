require 'rails_helper'

feature 'summary summary feature' do
  describe 'awaiting summary table' do
    before do
      signin_user
    end

    it 'redirects correctly', vcr: { cassette_name: :redirect_summary_index_feature } do
      visit prison_summary_path('LEI')
      expect(page).to have_current_path prison_summary_allocated_path('LEI')
    end

    it 'displays offenders awaiting information', vcr: { cassette_name: :awaiting_information_feature } do
      visit prison_summary_pending_path('LEI')

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
      expect(page).to have_css('.pagination ul.links li', count: 16)
    end

    it 'handles sorting params', vcr: { cassette_name: :summary_sorting_feature } do
      get_ids = lambda {
        all('tbody tr td').map(&:text).select { |c|
          /[A-Z][0-9.][0-9.][0-9.][0-9.][A-Z][A-Z]/.match(c)
        }
      }

      visit prison_summary_pending_path('LEI', sort: 'last_name')  # Default direction is asc.
      asc_cells = get_ids.call

      visit prison_summary_pending_path('LEI', sort: 'last_name desc')
      desc_cells = get_ids.call

      expect(asc_cells).not_to match_array(desc_cells)
    end

    it 'displays offenders pending allocation', vcr: { cassette_name: :awaiting_allocation_feature } do
      visit prison_summary_unallocated_path('LEI')

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('Update information')
    end

    it 'displays offenders already allocated', vcr: { cassette_name: :allocated_offenders_feature } do
      visit prison_summary_allocated_path('LEI')

      expect(page).to have_css('.govuk-tabs__tab')
      expect(page).to have_content('See allocations')
    end
  end

  describe 'paging' do
    it 'shows pages for allocation', vcr: { cassette_name: :allocated_offenders_paged_feature } do
      signin_user

      visit prison_summary_pending_path('LEI')
      expect(page).to have_link('Next')
      expect(page).not_to have_link('Previous')
      expect(page).not_to have_link('1', exact: true)

      visit prison_summary_pending_path('LEI', page: 2)
      expect(page).to have_link('Next')
      expect(page).to have_link('Previous')
      expect(page).not_to have_link('2', exact: true)

      visit prison_summary_pending_path('LEI', page: 117)
      expect(page).not_to have_link('Next')
      expect(page).to have_link('Previous')
      expect(page).not_to have_link('117', exact: true)
      expect(page).not_to have_link('118', exact: true)
    end
  end
end
