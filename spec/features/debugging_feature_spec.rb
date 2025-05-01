require 'rails_helper'

feature 'Provide debugging information for our team to use' do
  let(:nomis_offender_id) { "G3182GG" }
  let(:prison) { Prison.find 'LEI' }

  before do
    allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).and_return(nil)
    allow(Sentences).to receive(:for).and_return([])
    # allow(HmppsApi::PrisonApi::MovementApi).to receive(:movements_for).and_return(double(in?: true).as_null_object)
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
  end
end
