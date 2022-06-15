require 'rails_helper'

feature 'Provide debugging information for our team to use' do
  let(:nomis_offender_id) { "G3182GG" }
  let(:prison) { Prison.find 'LEI' }

  before do
    signin_global_admin_user
  end

  context 'when debugging an individual offender' do
    it 'returns information for an unallocated offender', vcr: { cassette_name: 'prison_api/debugging_feature' } do
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: nomis_offender_id
      click_on('search-button')

      expect(page).to have_css('tbody tr', count: 42)
      expect(page).to have_content("Not currently allocated")
    end

    it 'returns information for an allocated offender', vcr: { cassette_name: 'prison_api/debugging_allocated_offender_feature' } do
      create(:allocation_history,
             prison: 'LEI',
             nomis_offender_id: nomis_offender_id,
             primary_pom_name: "Rossana Spinka"
            )
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: nomis_offender_id
      click_on('search-button')

      expect(page).to have_css('tbody tr', count: 47)

      pom_table_row = page.find(:css, 'tr.govuk-table__row#pom', text: 'POM')

      within pom_table_row do
        expect(page).to have_content('POM Rossana Spinka')
      end

      movement_table_row = page.find(:css, 'tr.govuk-table__row#movement_date', text: 'Movement date')

      within movement_table_row do
        expect(page).to have_content('Movement date 29 Mar 2017')
      end

      oasys_assessment_row = page.find(:css, 'tr.govuk-table__row#oasys-date')

      within oasys_assessment_row do
        expect(page).to have_content('No OASys information')
      end
    end

    it 'can handle an incorrect offender number', vcr: { cassette_name: 'prison_api/debugging_incorrect_offender_feature' } do
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: "A1234BC"
      click_on('search-button')

      expect(page).to have_content("No offender was found, please check the offender number and try again")
    end

    it 'can handle no offender number being entered', vcr: { cassette_name: 'prison_api/debugging_no_offender_feature' } do
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: ""
      click_on('search-button')

      expect(page).to have_content("No offender was found, please check the offender number and try again")
    end

    context 'when offender does not have a sentence start date',
            vcr: { cassette_name: 'prison_api/debugging_no_sentence_start_date_for_offender_feature' } do
      let(:api_non_sentenced_offender) do
        build(:hmpps_api_offender,
              prisonerNumber: nomis_offender_id,
              sentence: attributes_for(:sentence_detail, :unsentenced))
      end
      let(:case_info) { create(:case_information, case_allocation: CaseInformation::NPS, offender: build(:offender, nomis_offender_id: nomis_offender_id)) }
      let(:non_sentenced_offender) do
        build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_non_sentenced_offender)
      end

      before do
        allow(OffenderService).to receive(:get_offender).and_return(non_sentenced_offender)
      end

      it 'shows the page without crashing' do
        visit prison_debugging_path('LEI')

        expect(page).to have_text('Debugging')
        fill_in 'offender_no', with: nomis_offender_id
        click_on('search-button')

        within '#sentenced' do
          expect(page).to have_content('No')
        end

        expect(page).to have_content 'OMIC policy does not apply to this offender'
      end
    end
  end
end
