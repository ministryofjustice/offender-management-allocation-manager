require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_637 }
  let(:nomis_offender_id) { 'G4273GI' }
  let(:tomorrow) { Date.tomorrow }

  let(:prison) { 'LEI' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }
  let(:elite2bookingsapi) { "#{elite2api}/offender-sentences/bookings" }

  # create 21 allocations for prisoners named A-K so that we can verify that default sorted paging works
  before do
    create(:case_information, nomis_offender_id: 'G7266VD')
    create(:case_information, nomis_offender_id: 'G8563UA')
    create(:case_information, nomis_offender_id: 'G6068GV')
    create(:case_information, nomis_offender_id: 'G0572VU')
    create(:case_information, nomis_offender_id: 'G8668GF')
    create(:case_information, nomis_offender_id: 'G9465UP')
    create(:case_information, nomis_offender_id: 'G9372GQ')
    create(:case_information, nomis_offender_id: 'G1618UI')
    create(:case_information, nomis_offender_id: 'G4328GK')
    create(:case_information, nomis_offender_id: 'G4143VX')
    create(:case_information, nomis_offender_id: 'G8180UO')
    create(:case_information, nomis_offender_id: 'G8909GV')
    create(:case_information, nomis_offender_id: 'G8339GD')
    create(:case_information, nomis_offender_id: 'G1992GH')
    create(:case_information, nomis_offender_id: 'G1986GG')
    create(:case_information, nomis_offender_id: 'G6262GI')
    create(:case_information, nomis_offender_id: 'G6653UC')
    create(:case_information, nomis_offender_id: 'G1718GG')
    create(:case_information, nomis_offender_id: 'G4706UP')
    create(:case_information, nomis_offender_id: 'G9344UG')
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', welsh_offender: 'Yes')

    create(:allocation_version, nomis_offender_id: 'G7266VD', primary_pom_nomis_id: '485637', nomis_booking_id: '1073602')
    create(:allocation_version, nomis_offender_id: 'G8563UA', primary_pom_nomis_id: '485637', nomis_booking_id: '1020605')
    create(:allocation_version, nomis_offender_id: 'G6068GV', primary_pom_nomis_id: '485637', nomis_booking_id: '1030841')
    create(:allocation_version, nomis_offender_id: 'G0572VU', primary_pom_nomis_id: '485637', nomis_booking_id: '861029')
    create(:allocation_version, nomis_offender_id: 'G8668GF', primary_pom_nomis_id: '485637', nomis_booking_id: '1106348')
    create(:allocation_version, nomis_offender_id: 'G9465UP', primary_pom_nomis_id: '485637', nomis_booking_id: '1186259')
    create(:allocation_version, nomis_offender_id: 'G9372GQ', primary_pom_nomis_id: '485637', nomis_booking_id: '752833')
    create(:allocation_version, nomis_offender_id: 'G1618UI', primary_pom_nomis_id: '485637', nomis_booking_id: '1161236')
    create(:allocation_version, nomis_offender_id: 'G4328GK', primary_pom_nomis_id: '485637', nomis_booking_id: '1055341')
    create(:allocation_version, nomis_offender_id: 'G4143VX', primary_pom_nomis_id: '485637', nomis_booking_id: '1083858')
    create(:allocation_version, nomis_offender_id: 'G8180UO', primary_pom_nomis_id: '485637', nomis_booking_id: '1172076')
    create(:allocation_version, nomis_offender_id: 'G8909GV', primary_pom_nomis_id: '485637', nomis_booking_id: '877782')
    create(:allocation_version, nomis_offender_id: 'G8339GD', primary_pom_nomis_id: '485637', nomis_booking_id: '260708')
    create(:allocation_version, nomis_offender_id: 'G1992GH', primary_pom_nomis_id: '485637', nomis_booking_id: '1179167')
    create(:allocation_version, nomis_offender_id: 'G1986GG', primary_pom_nomis_id: '485637', nomis_booking_id: '1165890')
    create(:allocation_version, nomis_offender_id: 'G6262GI', primary_pom_nomis_id: '485637', nomis_booking_id: '961997')
    create(:allocation_version, nomis_offender_id: 'G6653UC', primary_pom_nomis_id: '485637', nomis_booking_id: '1009990')
    create(:allocation_version, nomis_offender_id: 'G1718GG', primary_pom_nomis_id: '485637', nomis_booking_id: '928042')
    create(:allocation_version, nomis_offender_id: 'G4706UP', primary_pom_nomis_id: '485637', nomis_booking_id: '1180800')
    create(:allocation_version, nomis_offender_id: 'G9344UG', primary_pom_nomis_id: '485637', nomis_booking_id: '841994')
    create(:allocation_version, nomis_offender_id: 'G4273GI', primary_pom_nomis_id: '485637', nomis_booking_id: '1153753')

    stub_request(:get, elite2listapi).
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '1',
          'Page-Offset' => '1'
        }).
      to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '3' })

    stub_request(:get, elite2listapi).
    with(
      headers: {
        'Authorization' => 'Bearer token',
        'Expect' => '',
        'Page-Limit' => '200',
        'Page-Offset' => '200'
      }).
    to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '3' })

    stub_request(:get, elite2listapi).
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '200',
          'Page-Offset' => '0'
        }).
      to_return(status: 200,
                body: [{ "bookingId": 754_207, "bookingNo": "K09211", "offenderNo": "G7806VO", "firstName": "ONGMETAIN",
                         "lastName": "ABDORIA", "dateOfBirth": "1990-12-06",
                         "age": 28, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                         "facialImageId": 1_392_829,
                         "categoryCode": "C", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" },
                       { "bookingId": 754_206, "bookingNo": "K09212", "offenderNo": "G1234VV", "firstName": "ROSS",
                         "lastName": "JONES", "dateOfBirth": "2004-02-02",
                         "age": 15, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                         "facialImageId": 1_392_900,
                         "categoryCode": "D", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" },
                       { "bookingId": 1, "bookingNo": "K09213", "offenderNo": "G1234XX", "firstName": "BOB",
                         "lastName": "SMITH", "dateOfBirth": "1995-02-02",
                         "age": 34, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                         "facialImageId": 1_392_900,
                         "categoryCode": "D", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" }
                ].to_json)
    stub_request(:post, elite2bookingsapi).
      with(body: "[754207,754206,1]").
      to_return(status: 200, body: [
        { "bookingId": 754_207, "offenderNo": "G4912VX", "firstName": "EASTZO", "lastName": "AUBUEL", "agencyLocationId": "WEI",
          "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                              "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                              "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                              "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                              "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
          "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
        { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": "WEI",
          "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                              "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                              "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                              "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                              "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
          "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }
        ].to_json, headers: {})

    allow_any_instance_of(Nomis::OffenderBase).to receive(:handover_start_date).and_return([tomorrow, nil])
  end

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
      signin_pom_user

      visit prison_caseload_index_path('LEI')
    end

    it 'displays paginated cases for a specific POM' do
      expect(page).to have_content("Showing 1 - 21 of 21 results")
      expect(page).to have_content("Your caseload (21)")
      NAMES.first(20).each_with_index do |name, index|
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
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

    it 'can be searched by supporting role' do
      select 'Supporting', from: 'role'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 14 of 14 results')
    end

    it 'shows the tier' do
      within('.offender_row_20 .tier') do
        expect(page).to have_content('A')
      end
    end

    it 'can be searched by responsible role' do
      select 'Responsible', from: 'role'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 7 of 7 results')
    end
  end

  context 'when looking at handover start', vcr: { cassette_name: :show_poms_caseload_handover_start } do
    before {
      signin_pom_user
      visit prison_caseload_index_path('LEI')
    }

    it 'shows the number of upcoming handovers' do
      within('.upcoming-handover-count') do
        expect(find('a').text).to eq('21')
      end
    end

    it 'can show us all upcoming handovers' do
      within('.upcoming-handover-count') do
        click_link('21')
      end

      expect(page).to have_css('tbody tr.govuk-table__row', count: 21)
    end
  end

  it 'allows a POM to view the prisoner profile page for a specific offender',  vcr: { cassette_name: :show_poms_caseload_prisoner_profile } do
    signin_pom_user
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
    signin_pom_user
    visit prison_caseload_index_path('LEI')
    within('.new-cases-count') do
      click_link('1')
    end

    expect(page).to have_content("New cases")
    expect(page).to have_content("Abbella, Ozullirn")
  end

  it 'can sort all cases that have been allocated to a specific POM in the last week', :versioning, vcr: { cassette_name: :show_and_sort_new_cases } do
    # Sign in as a POM
    signin_pom_user
    visit prison_caseload_index_path('LEI')
    within('.new-cases-count') do
      click_link('1')
    end

    expect(page).to have_content("New cases")

    expected_name = 'Abbella, Ozullirn'

    # The first name...
    within('.offender_row_0') do
      expect(find('.prisoner-name').text).to eq(expected_name)
    end

    # After sorting ...
    click_link('Prisoner name')

    # Should be the last name
    within('.offender_row_20') do
      expect(find('.prisoner-name').text).to eq(expected_name)
    end
  end

  it 'stops staff without the POM role from viewing the my caseload page', vcr: { cassette_name: :non_pom_caseload }  do
    signin_user('NON_POM_GEN')
    visit prison_caseload_index_path('LEI')
    # root path will redirect to default dashboard
    expect(page).to have_current_path('/prisons/LEI/dashboard')
  end
end
