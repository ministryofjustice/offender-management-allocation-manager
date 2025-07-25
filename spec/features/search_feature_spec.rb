# frozen_string_literal: true

require 'rails_helper'

feature 'Search for offenders', flaky: true do
  before do
    allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).and_return(nil)
    signin_spo_user [prison_code]
  end

  context 'when male prison', vcr: { cassette_name: 'prison_api/dashboard_search_feature' } do
    let(:prison_code) { 'LEI' }

    it 'Can search from the dashboard' do
      visit root_path

      expect(page).to have_text(I18n.t('service_name'))
      fill_in 'q', with: 'Cal'
      click_on('search-button')

      expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
      expect(page).to have_css('tbody tr', count: 5)
    end

    it 'Has valid offender name link' do
      visit root_path
      fill_in 'q', with: 'Cal'
      click_on('search-button')

      # Click on first offender name
      find('.allocated_offender_row_0 .govuk-table__cell:first a').click
      expect(page).to have_title "View case information"
    end

    it 'Has valid Missing details link' do
      visit root_path
      fill_in 'q', with: 'Cal'
      click_on('search-button')

      # Just check that link can be clicked on without crashing
      within '.allocated_offender_row_0' do
        click_link 'Add missing details'
      end
    end
  end

  context "with female prison" do
    let(:prison) { create(:womens_prison) }
    let(:prison_code) { prison.code }
    let(:offenders) { build_list(:nomis_offender, 5, prisonId: prison.code, complexityLevel: 'high') }
    let(:pom) { build(:pom) }

    before do
      stub_offenders_for_prison(prison_code, offenders)
      stub_spo_user pom
      stub_poms prison_code, [pom]
    end

    it 'has a valid missing info link' do
      visit search_prison_prisoners_path(prison_code)

      # Just check that link can be clicked on without crashing
      within '.allocated_offender_row_0' do
        click_link 'Add missing details'
      end
    end
  end

  context 'with a single allocation' do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: 'G5359UP'))
      create(:allocation_history, prison: prison_code, nomis_offender_id: 'G5359UP')
    end

    let(:prison_code) { 'LEI' }

    it 'Can search from the Allocations summary page', vcr: { cassette_name: 'prison_api/allocated_search_feature' } do
      visit allocated_prison_prisoners_path(prison_code)

      expect(page).to have_text('See allocations')
      fill_in 'q', with: 'Fran'
      click_on('search-button')

      expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
      expect(page).to have_css('tbody tr', count: 10)
    end

    it 'Can search from the Awaiting Allocation summary page', vcr: { cassette_name: 'prison_api/waiting_allocation_search_feature' } do
      visit unallocated_prison_prisoners_path(prison_code)

      expect(page).to have_text('Make allocations')
      fill_in 'q', with: 'Tre'
      click_on('search-button')

      expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
      expect(page).to have_css('tbody tr', count: 1)
    end

    it 'Can search from the Missing Information summary page', vcr: { cassette_name: 'prison_api/missing_info_search_feature' } do
      visit missing_information_prison_prisoners_path(prison_code)

      expect(page).to have_text('Make allocations')
      fill_in 'q', with: 'Ste'
      click_on('search-button')

      expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
      expect(page).to have_css('tbody tr', count: 4)
    end
  end
end
