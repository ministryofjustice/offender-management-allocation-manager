require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_637 }
  let(:nomis_offender_id) { 'G4273GI' }

  before do
    CaseInformation.create(nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', omicable: 'Yes', prison: 'LEI')
  end

  it 'displays all cases for a specific POM',  vcr: { cassette_name: :show_poms_caseload } do
    signin_user('PK000223')

    visit confirm_allocations_path(nomis_offender_id, nomis_staff_id)

    click_button 'Complete allocation'

    visit caseload_index_path

    expect(page).to have_content("Your caseload")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'displays all cases that have been allocated to a specific POM in the last week', vcr: { cassette_name: :show_new_cases } do
    signin_user('PK000223')

    visit confirm_allocations_path(nomis_offender_id, nomis_staff_id)
    click_button 'Complete allocation'

    visit caseload_index_path
    click_link('1')

    expect(page).to have_content("New cases")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'allows staff without the POM role to view the my caseload page', vcr: { cassette_name: :non_pom_caseload }  do
    signin_user('NON_POM_GEN')
    visit caseload_index_path
    expect(page).to have_text("No allocated cases")
  end
end
