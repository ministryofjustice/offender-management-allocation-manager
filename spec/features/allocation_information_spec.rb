# frozen_string_literal: true

require "rails_helper"

feature "view an offender's allocation information" do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:nomis_offender_id_with_keyworker) { 'G3462VT' }
  let!(:nomis_offender_id_without_keyworker) { 'G8859UP' }
  let!(:allocated_at_tier) { 'A' }
  let!(:prison) { 'LEI' }
  let!(:recommended_pom_type) { 'probation' }
  let!(:pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      prison_code: prison,
      working_pattern: 1.0,
      status: 'Active'
    )
  }
  let(:offender_no) { "G4273GI" }

  before do
    signin_spo_user
  end

  context 'when offender does not have a key worker assigned' do
    before do
      create(:case_information, nomis_offender_id: nomis_offender_id_without_keyworker)
      create(
        :allocation,
        nomis_offender_id: nomis_offender_id_without_keyworker,
        primary_pom_nomis_id: probation_officer_nomis_staff_id,
        prison: prison
      )
    end

    it "displays 'Data not available'",
       vcr: { cassette_name: 'prison_api/show_allocation_information_keyworker_not_assigned' } do
      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_without_keyworker)

      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: "Alfew, Ef'Liaico")
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Data not available')
    end
  end

  context 'when an NPS, Determinate, English  offender has a key worker assigned' do
    context 'when the offender has over 10 months left to serve' do
      before do
        create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS', probation_service: 'England', tier: 'A')
        create(
          :allocation,
          nomis_offender_id: offender_no,
          primary_pom_nomis_id: probation_officer_nomis_staff_id,
          prison: prison,
          recommended_pom_type: recommended_pom_type
        )

        stub_api_calls_for_prison_allocation_path(sentence_start_date: (Time.zone.today - 4.months),
                                                  conditional_release_date: (Time.zone.today + 7.months),
                                                  automatic_release_date: (Time.zone.today + 7.months),
                                                  hdced: (Time.zone.today + 7.months))

        visit prison_allocation_path('LEI', nomis_offender_id: offender_no)
      end

      it "displays a POM as responsible" do
        expect(page).to have_content('Responsible')
      end

      it "displays the case owner as custody" do
        expect(page).to have_css('.govuk-table__cell', text: 'Custody')
      end

      it "displays a badge" do
        expect(page).to have_css('#prisoner-case-type', text: 'Determinate')
      end
    end

    context 'when the offender has less than 10 months left to serve' do
      before do
        create(:case_information, nomis_offender_id: offender_no)
        create(
          :allocation,
          nomis_offender_id: offender_no,
          primary_pom_nomis_id: probation_officer_nomis_staff_id,
          prison: prison,
          allocated_at_tier: allocated_at_tier,
          recommended_pom_type: recommended_pom_type
        )

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
      create(:case_information, nomis_offender_id: nomis_offender_id_with_keyworker)
      create(
        :allocation,
        nomis_offender_id: nomis_offender_id_with_keyworker,
        primary_pom_nomis_id: probation_officer_nomis_staff_id,
        prison: prison,
        allocated_at_tier: allocated_at_tier,
        recommended_pom_type: recommended_pom_type
      )
    end

    context 'without VCR' do
      before do
        stub_api_calls_for_prison_allocation_path(sentence_start_date: "2020-01-01",
                                                  conditional_release_date: "2020-06-02",
                                                  automatic_release_date: "2020-06-02",
                                                  hdced: "2020-06-02")
        visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)
      end

      let(:offender_no) { nomis_offender_id_with_keyworker }

      it "displays the Key Worker's details" do
        expect(page).to have_css('h1', text: 'Allocation information')

        # Pom
        expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
        # Keyworker
        expect(page).to have_css('.govuk-table__cell', text: 'Bull, Dom')
      end

      it "displays a link to the prisoner's New Nomis profile" do
        expect(page).to have_css('.govuk-table__cell', text: 'View DPS Profile')
        expect(find_link('View DPS Profile')[:target]).to eq('_blank')
        expect(find_link('View DPS Profile')[:href]).to include("offenders/#{nomis_offender_id_with_keyworker}/quick-look")
      end

      it 'displays a link to allocate a co-worker' do
        table_row = page.find(:css, 'tr.govuk-table__row', text: 'Co-working POM')

        within table_row do
          expect(page).to have_link('Allocate',
                                    href: new_prison_coworking_path('LEI', nomis_offender_id_with_keyworker))
          expect(page).to have_content('Co-working POM N/A')
        end
      end

      it 'displays a link to the allocation history' do
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

    context 'with VCR' do
      before do
        visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)
      end

      it 'displays the name of the allocated co-worker', vcr: { cassette_name: 'prison_api/show_allocation_information_display_coworker_name' } do
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
    end
  end

private

  def stub_api_calls_for_prison_allocation_path(sentence_start_date:, conditional_release_date:, automatic_release_date:, hdced:)
    stub_request(:post, "#{ApiHelper::AUTH_HOST}/auth/oauth/token?grant_type=client_credentials").
            to_return(body: {}.to_json)

    stub_request(:get, "#{ApiHelper::T3}/users/MOIC_POM").
      to_return(body: { 'staffId': 1 }.to_json)
    stub_pom_emails(1, [])

    stub_offender(build(:nomis_offender, offenderNo: offender_no,
                        sentence: attributes_for(:sentence_detail,
                                                 sentenceStartDate: sentence_start_date,
                                                 conditionalReleaseDate: conditional_release_date,
                                                 automaticReleaseDate: automatic_release_date,
                                                 homeDetentionCurfewEligibilityDate: hdced
                                        )))

    stub_request(:get, "#{ApiHelper::T3}/staff/roles/LEI/role/POM").
      to_return(body: [{ staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01", agencyId: "LEI", agencyDescription: "Leeds(HMP)", fromDate: "2019-01-22", position: "PRO", positionDescription: "PrisonOfficer", role: "POM", roleDescription: "Prison Offender Manager", scheduleType: "FT", scheduleTypeDescription: "FullTime", hoursPerWeek: 35 }].to_json)

    stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/LEI/offender/#{offender_no}").
      to_return(body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json)

    stub_request(:get, "#{ApiHelper::T3}/staff/485636").
      to_return(body: { staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01" }.to_json)
  end
end
