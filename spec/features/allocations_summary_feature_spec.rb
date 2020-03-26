require 'rails_helper'

feature 'summary summary feature' do
  before do
    signin_user
  end

  describe 'awaiting summary table' do
    it 'redirects correctly', vcr: { cassette_name: :redirect_summary_index_feature } do
      visit prison_summary_path('LEI')
      expect(page).to have_current_path prison_summary_allocated_path('LEI')
    end

    it 'displays offenders awaiting information', vcr: { cassette_name: :awaiting_information_feature } do
      visit prison_summary_pending_path('LEI')

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing information')
      expect(page).to have_css('.pagination ul.links li', count: 16)
    end

    it 'displays offenders pending allocation', vcr: { cassette_name: :awaiting_allocation_feature } do
      visit prison_summary_unallocated_path('LEI')

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing information')
    end

    it 'displays offenders already allocated', vcr: { cassette_name: :allocated_offenders_feature } do
      visit prison_summary_allocated_path('LEI')

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('See allocations')
    end

    it 'displays offenders just arrived allocated', vcr: { cassette_name: :new_offenders_feature } do
      visit prison_summary_new_arrivals_path('LEI')

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Newly arrived')
    end

    it 'displays offenders approaching their handover date', vcr: { cassette_name: :approaching_handover_feature } do
      visit prison_summary_handovers_path('LEI')

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Case handover status')
    end
  end
end
