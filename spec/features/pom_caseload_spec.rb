require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_637 }
  let(:nomis_offender_id) { 'G4273GI' }

  # create 11 allocations for prisoners named A-K so that we can verify that default sorted paging works
  let!(:offender11_case_info) { create(:case_information, nomis_offender_id: 'G8180UO') }
  let!(:offender10_case_info) { create(:case_information, nomis_offender_id: 'G8909GV') }
  let!(:offender9_case_info) { create(:case_information, nomis_offender_id: 'G8339GD') }
  let!(:offender8_case_info) { create(:case_information, nomis_offender_id: 'G1992GH') }
  let!(:offender7_case_info) { create(:case_information, nomis_offender_id: 'G1986GG') }
  let!(:offender6_case_info) { create(:case_information, nomis_offender_id: 'G6262GI') }
  let!(:offender5_case_info) { create(:case_information, nomis_offender_id: 'G6653UC') }
  let!(:offender4_case_info) { create(:case_information, nomis_offender_id: 'G1718GG') }
  let!(:offender3_case_info) { create(:case_information, nomis_offender_id: 'G4706UP') }
  let!(:offender2_case_info) { create(:case_information, nomis_offender_id: 'G9344UG') }
  let!(:offender1_case_info) do
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', omicable: 'Yes')
  end

  context 'when paginating', vcr: { cassette_name: :show_poms_caseload } do
    NAMES = ["Abbella, Ozullirn", "Bennany, Yruicafar", "Cadary, Avncent", "Daijedo, Egvaning",
             'Ebonuardo, Omimchi', 'Felitha, Asjmonzo', 'Gabrijah, Eastzo', 'Hah, Dyfastoaul',
             'Ibriyah, Aiamce', 'Jabexia, Elnuunbo', 'Kaceria, Omaertain']

    before do
      signin_user('PK000223')

      [offender1_case_info, offender2_case_info, offender3_case_info, offender4_case_info,
       offender5_case_info, offender6_case_info, offender7_case_info, offender8_case_info,
       offender9_case_info, offender10_case_info, offender11_case_info].each do |case_info|
        visit prison_confirm_allocation_path('LEI', case_info.nomis_offender_id, nomis_staff_id)
        click_button 'Complete allocation'
      end
      visit prison_caseload_index_path('LEI')
    end

    it 'displays paginated cases for a specific POM' do
      expect(page).to have_content("Showing 1 - 10 of 11 results")
      expect(page).to have_content("Your caseload")
      NAMES.first(10).each_with_index do |name, index|
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
      click_link 'Next »'
      expect(page).to have_content("Showing 11 - 11 of 11 results")
      expect(page).to have_content(NAMES.last)
    end

    it 'can be reverse sorted by name' do
      click_link 'Prisoner name'
      NAMES.last(10).reverse.each_with_index do |name, index|
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by release date' do
      page.all('th')[2].find('a').click
      within '.offender_row_2' do
        expect(page).to have_content('Kaceria, Omaertain')
      end
      within '.offender_row_3' do
        expect(page).to have_content('Gabrijah, Eastzo')
      end
    end

    it 'can be searched by string' do
      fill_in 'q', with: 'oz'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 1 of 1 results')
    end

    it 'can be searched by number' do
      fill_in 'q', with: '8180U'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 1 of 1 results')
      within '.offender_row_0' do
        expect(page).to have_content('Kaceria, Omaertain')
      end
    end

    it 'can be searched by role' do
      select 'Supporting', from: 'role'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 7 of 7 results')
    end
  end

  it 'allows a POM to view the prisoner profile page for a specific offender',  vcr: { cassette_name: :show_poms_caseload_prisoner_profile } do
    signin_user('PK000223')

    visit prison_confirm_allocation_path('LEI', nomis_offender_id, nomis_staff_id)

    click_button 'Complete allocation'

    visit prison_caseload_index_path('LEI')

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

    visit prison_confirm_allocation_path('LEI', nomis_offender_id, nomis_staff_id)
    click_button 'Complete allocation'

    visit prison_caseload_index_path('LEI')
    click_link('1')

    expect(page).to have_content("New cases")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'stops staff without the POM role from viewing the my caseload page', vcr: { cassette_name: :non_pom_caseload }  do
    signin_user('NON_POM_GEN')
    visit prison_caseload_index_path('LEI')
    # root path will redirect to default dashboard
    expect(page).to have_current_path('/prisons/LEI/dashboard')
  end
end
