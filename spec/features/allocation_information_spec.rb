# frozen_string_literal: true

require "rails_helper"

feature "view an offender's allocation information", :versioning do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:nomis_offender_id_with_keyworker) { 'G4273GI' }
  let!(:nomis_offender_id_without_keyworker) { 'G9403UP' }
  let!(:allocated_at_tier) { 'A' }
  let!(:prison) { 'LEI' }
  let!(:recommended_pom_type) { 'probation' }
  let!(:pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }
  let(:offender_no) { "G4273GI" }

  before do
    signin_user
  end

  context 'with community information' do
    before do
      create_case_information_for(nomis_offender_id_without_keyworker)
      create_allocation(nomis_offender_id_without_keyworker)
    end

    it 'displays community information with update links', :raven_intercept_exception,
       vcr: { cassette_name: :show_allocation_information_community_info } do
      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_without_keyworker)
      expect(page).to have_css('h1', text: 'Allocation information')

      within('#community_information') do
        within("#probation_service") do
          expect(page).to have_content('Wales')
          expect(page).to have_link('Change', href: edit_prison_case_information_path('LEI', nomis_offender_id_without_keyworker))
        end

        expect(page).to have_content('Local divisional unit (LDU)')
        expect(page).to have_content('LDU Name')
        expect(page).to have_content('Local divisional unit (LDU) email address')
        expect(page).to have_content('testldu@example.org')

        within("#team") do
          expect(page).to have_content('A nice team')
          expect(page).to have_link('Change', href: edit_prison_case_information_path('LEI', nomis_offender_id_without_keyworker))
        end

        expect(page).to have_content('COM')
      end
    end
  end

  context 'when offender does not have a key worker assigned' do
    before do
      create_case_information_for(nomis_offender_id_without_keyworker)
      create_allocation(nomis_offender_id_without_keyworker)
    end

    it "displays 'Data not available'", :raven_intercept_exception,
       vcr: { cassette_name: :show_allocation_information_keyworker_not_assigned } do
      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_without_keyworker)

      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: 'Albina, Obinins')
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Data not available')
    end
  end

  context 'when an NPS, Determinate, English  offender has a key worker assigned' do
    context 'when the offender has over 10 months left to serve' do
      before do
        create_case_information_for(offender_no)
        create_allocation(offender_no)

        stub_api_calls_for_prison_allocation_path(sentence_start_date: "2020-01-01",
                                                  conditional_release_date: "2020-11-02",
                                                  automatic_release_date: "2020-11-02",
                                                  hdced: "2020-11-02")

        visit prison_allocation_path('LEI', nomis_offender_id: offender_no)
      end

      it "displays a POM as responsible" do
        expect(page).to have_content('Responsible')
      end

      it "displays the case owner as custody" do
        expect(page).to have_css('.govuk-table__cell', text: 'Custody')
      end
    end

    context 'when the offender has less than 10 months left to serve' do
      before do
        create_case_information_for(offender_no)
        create_allocation(offender_no)

        stub_api_calls_for_prison_allocation_path(sentence_start_date: "2020-01-01",
                                                  conditional_release_date: "2020-06-02",
                                                  automatic_release_date: "2020-06-02",
                                                  hdced: "2020-06-02")

        visit prison_allocation_path('LEI', nomis_offender_id: offender_no)
      end

      it "displays a POM as supporting if the offender has less than 10 months left to serve" do
        expect(page).to have_content('Supporting')
      end

      it "displays the case owner as community" do
        expect(page).to have_css('.govuk-table__cell', text: 'Community')
      end
    end
  end

  context 'when Offender has a key worker assigned' do
    before do
      create_case_information_for(nomis_offender_id_with_keyworker)
      create_allocation(nomis_offender_id_with_keyworker)
      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)
    end

    it "displays the Key Worker's details", vcr: { cassette_name: :show_allocation_information_keyworker_assigned } do
      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: 'Abbella, Ozullirn')
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Bull, Dom')
    end

    it "displays a link to the prisoner's New Nomis profile", vcr: { cassette_name: :show_allocation_information_new_nomis_profile } do
      expect(page).to have_css('.govuk-table__cell', text: 'View NOMIS profile')
      expect(find_link('View NOMIS profile')[:target]).to eq('_blank')
      expect(find_link('View NOMIS profile')[:href]).to include('offenders/G4273GI/quick-look')
    end

    it 'displays a link to allocate a co-worker', vcr: { cassette_name: :show_allocation_information_display_coworker_link } do
      table_row = page.find(:css, 'tr.govuk-table__row', text: 'Co-working POM')

      within table_row do
        expect(page).to have_link('Allocate',
                                  href: new_prison_coworking_path('LEI', nomis_offender_id_with_keyworker))
        expect(page).to have_content('Co-working POM N/A')
      end
    end

    it 'displays the name of the allocated co-worker', vcr: { cassette_name: :show_allocation_information_display_coworker_name } do
      allocation = Allocation.find_by(nomis_offender_id: nomis_offender_id_with_keyworker)

      allocation.update!(event: Allocation::ALLOCATE_SECONDARY_POM,
                         secondary_pom_nomis_id: 485_926,
                         secondary_pom_name: "Pom, Moic")

      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)

      table_row = page.find(:css, 'tr.govuk-table__row#co-working-pom', text: 'Co-working POM')

      within table_row do
        expect(page).to have_link('Remove')
        expect(page).to have_content('Co-working POM Pom, Moic')
      end
    end

    it 'displays a link to the allocation history', vcr: { cassette_name: :show_allocation_information_history_link } do
      table_row = page.find(:css, 'tr.govuk-table__row', text: 'Allocation history')

      within table_row do
        expect(page).to have_link('View')
        expect(page).to have_content("POM allocated - #{Time.zone.now.strftime('%d/%m/%Y')}")
      end
    end

    context 'without auto_delius_import enabled' do
      it 'displays change links' do
        expect(page).to have_content 'Change'
      end
    end

    context 'with auto_delius_import enabled' do
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        test_strategy.switch!(:auto_delius_import, true)
      end

      after do
        test_strategy.switch!(:auto_delius_import, false)
      end

      it 'does not display change links' do
        visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)
        expect(page).not_to have_content 'Change'
      end
    end
  end

  def create_case_information_for(offender_no)
    create(:case_information,
           nomis_offender_id: offender_no,
           tier: 'A',
           case_allocation: 'NPS',
           welsh_offender: 'No'
    )
  end

  def create_allocation(offender_no)
    create(
      :allocation,
      nomis_offender_id: offender_no,
      primary_pom_nomis_id: probation_officer_nomis_staff_id,
      prison: prison,
      allocated_at_tier: allocated_at_tier,
      recommended_pom_type: recommended_pom_type
    )
  end

private

  def stub_api_calls_for_prison_allocation_path(sentence_start_date:, conditional_release_date:, automatic_release_date:, hdced:)
    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/auth/oauth/token?grant_type=client_credentials").
            to_return(status: 200, body: {}.to_json, headers: {})

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/prisoners/#{offender_no}").
      to_return(status: 200, body: [{ offenderNo: offender_no, title: "MR", firstName: "OZULLIRN", middleNames: "TESSE", lastName: "ABBELLA", dateOfBirth: "1980-08-15", gender: "Male", sexCode: "M", nationalities: "sxiVsxi", currentlyInPrison: "Y", latestBookingId: "1153753", latestLocationId: "LEI", latestLocation: "Leeds(HMP)", internalLocation: "LEI-B-4-021", pncNumber: "97/39395W", croNumber: "043735/97V", ethnicity: "White:Eng./Welsh/Scot./N.Irish/British", birthCountry: "England", religion: "EfJSmIEfJSm", convictedStatus: "Convicted", imprisonmentStatus: "SENT03", receptionDate: "2016-11-26", maritalStatus: "sjedbztIaJRRzRZVIYadsjedbztIaJRRzRZVIYa" }].to_json)

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-sentences/bookings").
      with(body: "[1153753]").
        to_return(status: 200, body: [{ bookingId: 1_153_753, offenderNo: offender_no, firstName: "OZULLIRN", lastName: "ABBELLA", agencyLocationId: "LEI", sentenceDetail: { sentenceExpiryDate: "2023-06-03", conditionalReleaseDate: conditional_release_date, automaticReleaseDate: automatic_release_date, homeDetentionCurfewEligibilityDate: hdced,  licenceExpiryDate: "2023-05-22", bookingId: 1_153_753, sentenceStartDate: sentence_start_date, nonDtoReleaseDate: "2020-03-16", nonDtoReleaseDateType: "CRD", confirmedReleaseDate: "2020-02-07" }, dateOfBirth: "1980-08-15", agencyLocationDesc: "LEEDS(HMP)", internalLocationDesc: "B-4-021", facialImageId: 1_340_556 }].to_json, headers: {})

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-assessments/CATEGORY").
      with(body: "[\"#{offender_no}\"]").
        to_return(status: 200, body: [{ bookingId: 1_153_753, offenderNo: offender_no, classificationCode: "C", classification: "CatC", assessmentCode: "CATEGORY", assessmentDescription: "Categorisation", cellSharingAlertFlag: false, assessmentDate: "2017-01-19", nextReviewDate: "2019-09-09", approvalDate: "2017-01-20", assessmentAgencyId: "LEI", assessmentStatus: "A", assessmentSeq: 5 }].to_json, headers: {})

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/bookings/1153753/mainOffence").
      to_return(status: 200, body: [{ bookingId: 1_153_753, offenceDescription: "Section 18 - wounding with intent to resist / prevent arrest" }].to_json, headers: {})

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/roles/LEI/role/POM").
      to_return(status: 200, body: [{ staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01", agencyId: "LEI", agencyDescription: "Leeds(HMP)", fromDate: "2019-01-22", position: "PRO", positionDescription: "PrisonOfficer", role: "POM", roleDescription: "Prison Offender Manager", scheduleType: "FT", scheduleTypeDescription: "FullTime", hoursPerWeek: 35 }].to_json, headers: {})

    stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/LEI/offender/#{offender_no}").
      to_return(status: 200, body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json, headers: {})

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/485636").
      to_return(status: 200, body: { staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01" }.to_json, headers: {})
  end
end
