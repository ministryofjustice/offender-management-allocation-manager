require 'rails_helper'

feature 'Provide debugging information for our team to use' do
  let(:nomis_offender_id) { "G3182GG" }
  let(:prison) { Prison.find 'LEI' }

  before do
    allow_any_instance_of(DomainEvents::Event).to receive(:publish).and_return(nil)
    signin_global_admin_user
  end

  context 'when debugging an individual offender' do
    it 'returns information for an offender', vcr: { cassette_name: 'prison_api/debugging_allocated_offender_feature' } do
      create(:allocation_history,
             prison: 'LEI',
             nomis_offender_id: nomis_offender_id,
             primary_pom_name: "Rossana Spinka"
            )
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: nomis_offender_id
      click_on('search-button')

      expect(page).to have_content('Rossana Spinka')
      expect(page).to have_content('Movement date 29 Mar 2017')
      expect(page).to have_content('No OASys information')
    end

    it 'can handle an incorrect offender number', vcr: { cassette_name: 'prison_api/debugging_incorrect_offender_feature' } do
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: 'A1234BC'
      click_on('search-button')

      expect(page).to have_content('No offender was found')
    end

    it 'can handle no offender number being entered', vcr: { cassette_name: 'prison_api/debugging_no_offender_feature' } do
      visit prison_debugging_path('LEI')

      expect(page).to have_text('Debugging')
      fill_in 'offender_no', with: ''
      click_on('search-button')

      expect(page).to have_content('No offender was found')
    end
  end
end
