require 'rails_helper'

feature 'Inactive POM' do
  context 'when viewing an inactive POMs caseload', vcr: { cassette_name: 'prison_api/deallocate_non_pom_caseload' } do
    # We need an inactive POM to test this feature, Toby has had his POM role removed and therefore a good candidate!
    let(:inactive_pom)      { 485_595 }
    let(:nomis_offender_id) { "G7266VD" }
    let(:prison_code)            { "LEI" }
    let(:active_pom) { 485_926 }

    before do
      signin_spo_user

      create(
        :allocation_history,
        prison: prison_code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: inactive_pom,
        secondary_pom_nomis_id: active_pom
      )
      create(:pom_detail, prison_code: prison_code, nomis_staff_id: inactive_pom)
      visit prison_prisoner_allocation_path(prison_code, nomis_offender_id)
      expect(page).to have_text("This Prison Offender Manager does not appear to be active")
    end

    it 'will deallocate the caseload' do
      click_link("Set this POM's status to inactive")

      within first('.govuk-summary-list__row') do
        click_link "Change"
      end
      choose("Inactive")
      click_button("Save")

      expect(AllocationHistory.where(primary_pom_nomis_id: inactive_pom).count).to eq(0)
    end

    it "will redirect to the help page" do
      click_link("Guide to getting set up")
      expect(page).to have_current_path(help_step0_path)
    end
  end
end
