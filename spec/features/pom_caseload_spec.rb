require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_637 }
  let(:nomis_offender_id) { 'G4273GI' }

  before do
    CaseInformation.create(nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', omicable: 'Yes')
  end

  it 'displays all cases for a specific POM',  vcr: { cassette_name: :show_poms_caseload } do
    signin_user('PK000223')

    visit confirm_allocation_path(nomis_offender_id, nomis_staff_id)

    click_button 'Complete allocation'

    visit caseload_index_path

    expect(page).to have_content("Showing 1 - 1 of 1 results")
    expect(page).to have_content("Your caseload")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'allows a POM to view the prisoner profile page for a specific offender',  vcr: { cassette_name: :show_poms_caseload_prisoner_profile } do
    signin_user('PK000223')

    visit confirm_allocation_path(nomis_offender_id, nomis_staff_id)

    click_button 'Complete allocation'

    visit caseload_index_path

    within('.offender_row_0') do
      click_link 'View'
    end

    expect(page).to have_css('h2', text: 'Abbella, Ozullirn')
    expect(page).to have_content('15/08/1980')
    cat_code = find('h3#category-code').text
    expect(cat_code).to eq('C')
  end

  it 'displays all cases that have been allocated to a specific POM in the last week', vcr: { cassette_name: :show_new_cases } do
    signin_user('PK000223')

    visit confirm_allocation_path(nomis_offender_id, nomis_staff_id)
    click_button 'Complete allocation'

    visit caseload_index_path
    click_link('1')

    expect(page).to have_content("New cases")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'stops staff without the POM role from viewing the my caseload page', vcr: { cassette_name: :non_pom_caseload }  do
    signin_user('NON_POM_GEN')
    visit caseload_index_path
    expect(page).to have_current_path('/')
  end
end
