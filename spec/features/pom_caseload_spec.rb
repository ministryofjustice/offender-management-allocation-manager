require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_637 }
  let(:nomis_offender_id) { 'G4273GI' }

  # create 21 allocations for prisoners named A-K so that we can verify that default sorted paging works
  let!(:offender21_case_info) { create(:case_information, nomis_offender_id: 'G7266VD') }
  let!(:offender20_case_info) { create(:case_information, nomis_offender_id: 'G8563UA') }
  let!(:offender19_case_info) { create(:case_information, nomis_offender_id: 'G6068GV') }
  let!(:offender18_case_info) { create(:case_information, nomis_offender_id: 'G0572VU') }
  let!(:offender17_case_info) { create(:case_information, nomis_offender_id: 'G8668GF') }
  let!(:offender16_case_info) { create(:case_information, nomis_offender_id: 'G9465UP') }
  let!(:offender15_case_info) { create(:case_information, nomis_offender_id: 'G9372GQ') }
  let!(:offender14_case_info) { create(:case_information, nomis_offender_id: 'G1618UI') }
  let!(:offender13_case_info) { create(:case_information, nomis_offender_id: 'G4328GK') }
  let!(:offender12_case_info) { create(:case_information, nomis_offender_id: 'G4143VX') }
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
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', welsh_offender: 'Yes')
  end

  let!(:case_infos) {
    [
   offender1_case_info, offender2_case_info, offender3_case_info, offender4_case_info,
   offender5_case_info, offender6_case_info, offender7_case_info, offender8_case_info,
   offender9_case_info, offender10_case_info, offender11_case_info, offender12_case_info,
   offender13_case_info, offender14_case_info, offender15_case_info, offender16_case_info,
   offender17_case_info, offender18_case_info, offender19_case_info, offender20_case_info,
   offender21_case_info
    ]
  }

  let!(:allocations) {
    [
    create(:allocation_version, nomis_offender_id: 'G7266VD', primary_pom_nomis_id: '485637', nomis_booking_id: '1073602'),
    create(:allocation_version, nomis_offender_id: 'G8563UA', primary_pom_nomis_id: '485637', nomis_booking_id: '1020605'),
    create(:allocation_version, nomis_offender_id: 'G6068GV', primary_pom_nomis_id: '485637', nomis_booking_id: '1030841'),
    create(:allocation_version, nomis_offender_id: 'G0572VU', primary_pom_nomis_id: '485637', nomis_booking_id: '861029'),
    create(:allocation_version, nomis_offender_id: 'G8668GF', primary_pom_nomis_id: '485637', nomis_booking_id: '1106348'),
    create(:allocation_version, nomis_offender_id: 'G9465UP', primary_pom_nomis_id: '485637', nomis_booking_id: '1186259'),
    create(:allocation_version, nomis_offender_id: 'G9372GQ', primary_pom_nomis_id: '485637', nomis_booking_id: '752833'),
    create(:allocation_version, nomis_offender_id: 'G1618UI', primary_pom_nomis_id: '485637', nomis_booking_id: '1161236'),
    create(:allocation_version, nomis_offender_id: 'G4328GK', primary_pom_nomis_id: '485637', nomis_booking_id: '1055341'),
    create(:allocation_version, nomis_offender_id: 'G4143VX', primary_pom_nomis_id: '485637', nomis_booking_id: '1083858'),
    create(:allocation_version, nomis_offender_id: 'G8180UO', primary_pom_nomis_id: '485637', nomis_booking_id: '1172076'),
    create(:allocation_version, nomis_offender_id: 'G8909GV', primary_pom_nomis_id: '485637', nomis_booking_id: '877782'),
    create(:allocation_version, nomis_offender_id: 'G8339GD', primary_pom_nomis_id: '485637', nomis_booking_id: '260708'),
    create(:allocation_version, nomis_offender_id: 'G1992GH', primary_pom_nomis_id: '485637', nomis_booking_id: '1179167'),
    create(:allocation_version, nomis_offender_id: 'G1986GG', primary_pom_nomis_id: '485637', nomis_booking_id: '1165890'),
    create(:allocation_version, nomis_offender_id: 'G6262GI', primary_pom_nomis_id: '485637', nomis_booking_id: '961997'),
    create(:allocation_version, nomis_offender_id: 'G6653UC', primary_pom_nomis_id: '485637', nomis_booking_id: '1009990'),
    create(:allocation_version, nomis_offender_id: 'G1718GG', primary_pom_nomis_id: '485637', nomis_booking_id: '928042'),
    create(:allocation_version, nomis_offender_id: 'G4706UP', primary_pom_nomis_id: '485637', nomis_booking_id: '1180800'),
    create(:allocation_version, nomis_offender_id: 'G9344UG', primary_pom_nomis_id: '485637', nomis_booking_id: '841994'),
    create(:allocation_version, nomis_offender_id: 'G4273GI', primary_pom_nomis_id: '485637', nomis_booking_id: '1153753')
  ]
  }

  context 'when paginating', vcr: { cassette_name: :show_poms_caseload } do
    before do
      stub_const("NAMES", ["Abbella, Ozullirn", 'Allix, Aobmethani',
                           'Almesa, Akoresjan', 'Amabeth, Eeonyan', 'Anasterie, Aobmethani', 'Andexia, Obinins',
                           'Andoy, Demolarichard', 'Androne, Alblisdavid', 'Anikariah, Aeticake',
                           'Annole, Omistius', 'Anslana, Diydonopher',
                           "Bennany, Yruicafar", "Cadary, Avncent", "Daijedo, Egvaning",
                           'Ebonuardo, Omimchi', 'Felitha, Asjmonzo', 'Gabrijah, Eastzo', 'Hah, Dyfastoaul',
                           'Ibriyah, Aiamce', 'Jabexia, Elnuunbo', 'Kaceria, Omaertain'
      ])
      signin_user('PK000223')

      allocations

      visit prison_caseload_index_path('LEI')
    end

    it 'displays paginated cases for a specific POM' do
      expect(page).to have_content("Showing 1 - 20 of 21 results")
      expect(page).to have_content("Your caseload")
      NAMES.first(20).each_with_index do |name, index|
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
      click_link 'Next »'
      expect(page).to have_content("Showing 21 - 21 of 21 results")
      expect(page).to have_content(NAMES.last)
    end

    it 'can be reverse sorted by name' do
      click_link 'Prisoner name'
      NAMES.last(20).reverse.each_with_index do |name, index|
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by release date' do
      page.all('th')[2].find('a').click
      within '.offender_row_4' do
        expect(page).to have_content('Allix, Aobmethani')
      end
      within '.offender_row_5' do
        expect(page).to have_content('Andoy, Demolarichard')
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
      expect(page).to have_content('Showing 1 - 19 of 19 results')
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

  it 'displays all cases that have been allocated to a specific POM in the last week', :versioning, vcr: { cassette_name: :show_new_cases } do
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
