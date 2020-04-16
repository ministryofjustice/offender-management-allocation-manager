require 'rails_helper'

feature 'Provide debugging information for our team to use' do
  let(:nomis_offender_id) { "G1670VU" }

  context 'when debugging an individual offender' do
    it 'returns information for an unallocated offender', vcr: { cassette_name: :debugging_feature } do
      signin_user
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: nomis_offender_id
      click_on('search-button')

      expect(page).to have_css('tbody tr', count: 38)
      expect(page).to have_content("Not currently allocated")

      table_row = page.find(:css, 'tr.govuk-table__row#convicted', text: 'Convicted?')

      within table_row do
        expect(page).to have_content('Yes')
      end
    end

    it 'returns information for an allocated offender', vcr: { cassette_name: :debugging_allocated_offender_feature } do
      create(:allocation,
             nomis_offender_id: nomis_offender_id,
             primary_pom_name: "Rossana Spinka"
             )
      signin_user
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: nomis_offender_id
      click_on('search-button')

      expect(page).to have_css('tbody tr', count: 43)

      pom_table_row = page.find(:css, 'tr.govuk-table__row#pom', text: 'POM')

      within pom_table_row do
        expect(page).to have_content('POM Rossana Spinka')
      end

      movement_table_row = page.find(:css, 'tr.govuk-table__row#movement_date', text: 'Movement date')

      within movement_table_row do
        expect(page).to have_content('Movement date 20/07/2018')
      end
    end

    it 'can handle an incorrect offender number', vcr: { cassette_name: :debugging_incorrect_offender_feature } do
      signin_user
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: "A1234BC"
      click_on('search-button')

      expect(page).to have_content("No offender was found, please check the offender number and try again")
    end

    it 'can handle no offender number being entered', vcr: { cassette_name: :debugging_no_offender_feature } do
      signin_user
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: ""
      click_on('search-button')

      expect(page).to have_content("No offender was found, please check the offender number and try again")
    end
  end

  context 'when debugging at a prison level' do
    it 'displays a dashboard' do
      signin_user
      visit prison_debugging_prison_path('LEI')

      expect(page).to have_text("Prison Debugging")
      expect(page).to have_css('tbody tr', minimum: 220)
      expect(page).to have_css('.govuk-data-label', text: 'With missing information')
    end
  end
end
