# frozen_string_literal: true

require "rails_helper"

feature "view an offender's allocation information", flaky: true do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:nomis_offender_id_with_keyworker) { 'G6951VK' }
  let!(:nomis_offender_id_without_keyworker) { 'G8859UP' }
  let!(:allocated_at_tier) { 'A' }
  let!(:prison) { create(:prison) }
  let!(:recommended_pom_type) { 'probation' }
  let!(:pom_detail) do
    PomDetail.create(
      nomis_staff_id: probation_officer_nomis_staff_id,
      prison_code: prison.code,
      working_pattern: 1.0,
      status: 'Active'
    )
  end
  let(:offender_no) { "G4273GI" }

  before do
    signin_spo_user
  end

  context 'when offender does not have a key worker assigned' do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id_without_keyworker))
      create(
        :allocation_history,
        nomis_offender_id: nomis_offender_id_without_keyworker,
        primary_pom_nomis_id: probation_officer_nomis_staff_id,
        prison: prison
      )
    end

    it "displays 'Data not available'",
       flaky: true,
       vcr: { cassette_name: 'prison_api/show_allocation_information_keyworker_not_assigned' } do
      visit prison_prisoner_allocation_path('LEI', prisoner_id: nomis_offender_id_without_keyworker)

      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: "Alfew, Ef'Liaico")
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Data not available')
    end
  end

  context 'when an NPS, Determinate, English offender has a key worker assigned' do
    context 'when the offender has over 10 months left to serve' do
      before do
        create(:case_information, :english, offender: build(:offender, nomis_offender_id: offender_no), enhanced_resourcing: true, tier: 'A')
        create(
          :allocation_history,
          nomis_offender_id: offender_no,
          primary_pom_nomis_id: probation_officer_nomis_staff_id,
          prison: prison,
          recommended_pom_type: recommended_pom_type
        )

        stub_api_calls_for_prison_allocation_path(sentence_start_date: (Time.zone.today - 4.months),
                                                  conditional_release_date: (Time.zone.today + 7.months),
                                                  automatic_release_date: (Time.zone.today + 7.months),
                                                  hdced: (Time.zone.today + 7.months))

        visit prison_prisoner_allocation_path('LEI', prisoner_id: offender_no)
      end

      it "displays a POM as responsible" do
        expect(page).to have_content('Responsible')
      end

      it "displays the case owner as custody" do
        expect(page).to have_css('.govuk-table__cell', text: 'Responsible')
      end

      it "displays a badge" do
        expect(page).to have_css('#prisoner-case-type', text: 'Determinate')
      end
    end

    context 'when the offender has less than 10 months left to serve' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
        create(
          :allocation_history,
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

        visit prison_prisoner_allocation_path('LEI', prisoner_id: offender_no)
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
      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id_with_keyworker))
      create(
        :allocation_history,
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
        visit prison_prisoner_allocation_path('LEI', prisoner_id: nomis_offender_id_with_keyworker)
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
    end

    context 'with VCR' do
      before do
        visit prison_prisoner_allocation_path('LEI', prisoner_id: nomis_offender_id_with_keyworker)
      end

      it 'displays the name of the allocated co-worker',
         flaky: true, vcr: { cassette_name: 'prison_api/show_allocation_information_display_coworker_name' } do
        allocation = AllocationHistory.find_by(nomis_offender_id: nomis_offender_id_with_keyworker)

        allocation.update!(event: AllocationHistory::ALLOCATE_SECONDARY_POM,
                           secondary_pom_nomis_id: 485_926,
                           secondary_pom_name: "Pom, Moic")

        visit prison_prisoner_allocation_path('LEI', prisoner_id: nomis_offender_id_with_keyworker)

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
    stub_request(:post, "#{ApiHelper::AUTH_HOST}/auth/oauth/token?grant_type=client_credentials")
            .to_return(body: {}.to_json)

    stub_user('MOIC_POM', 1)
    stub_pom_emails(1, [])

    stub_offender(build(:nomis_offender, prisonerNumber: offender_no,
                                         sentence: attributes_for(:sentence_detail,
                                                                  sentenceStartDate: sentence_start_date,
                                                                  conditionalReleaseDate: conditional_release_date,
                                                                  automaticReleaseDate: automatic_release_date,
                                                                  homeDetentionCurfewEligibilityDate: hdced
                                                                 )))

    stub_request(:get, "#{ApiHelper::T3}/staff/roles/LEI/role/POM")
      .to_return(body: [{ staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01", agencyId: "LEI", agencyDescription: "Leeds(HMP)", fromDate: "2019-01-22", position: "PRO", positionDescription: "PrisonOfficer", role: "POM", roleDescription: "Prison Offender Manager", scheduleType: "FT", scheduleTypeDescription: "FullTime", hoursPerWeek: 35 }].to_json)

    stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/LEI/offender/#{offender_no}")
      .to_return(body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json)

    stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/485636")
      .to_return(body: { staffId: 485_636, firstName: "JENNY", lastName: "DUCKETT", status: "ACTIVE", gender: "F", dateOfBirth: "1970-01-01" }.to_json)
  end
end
