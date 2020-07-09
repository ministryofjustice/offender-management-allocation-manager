require 'rails_helper'

feature 'case information feature' do
  include ActiveJob::TestHelper
  before do
    ldu1 = create(:local_divisional_unit, code: "WELDU", name: "Welsh LDU", email_address: "WalesNPS@example.com")
    ldu2 = create(:local_divisional_unit, code: "ENLDU", name: "English LDU", email_address: "EnglishNPS@example.com")
    ldu3 = create(:local_divisional_unit, code: "OTHERLDU", name: "English LDU 2", email_address: nil)
    Team.create!(code: "WELSH1", name: 'NPS - Wales', shadow_code: "W01", local_divisional_unit: ldu1)
    Team.create!(code: "ENG1", name: 'NPS - England', shadow_code: "E01", local_divisional_unit: ldu2)
    Team.create!(code: "ENG2", name: 'NPS - England 2', shadow_code: "E02", local_divisional_unit: ldu3)
    Team.create!(code: "ENG3", name: 'NPS - England 3', shadow_code: "E03", local_divisional_unit: ldu2)
  end

  let(:nomis_offender_id) { 'G2911GD' } # This NOMIS id needs to appear on the first page of 'missing information' also a determinate offender
  let(:other_nomis_offender_id) { 'G4273GI' }

  let(:user_details) do
    user = Nomis::UserDetails.new
    user.staff_id = 423_142
    user.first_name = "JOHN"
    user.last_name = "SMITH"
    user.status = "ACTIVE"
    user.thumbnail_id = 231_232
    user.username = "MOIC_POM"
    user.email_address = ['spo_user@digital-justice.uk']
    user
  end

  let(:offender_name) { 'Ahmonis, Imanjah' }
  let(:notification_without_email) {
    "There’s more than one nDelius record with this NOMIS number #{nomis_offender_id} for #{offender_name}. The community probation team need to update nDelius."
  }
  let(:notification_with_email) {
    notification_without_email + " Automatic email sent."
  }

  context 'when creating case information' do
    context "when the offender is Scottish or Northern Irish" do
      context 'when the form has errors' do
        let(:offender_id) { 'G1821VA' }
        let(:error_msg) { "You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales" }

        before do
          signin_user
          visit new_prison_case_information_path('LEI', offender_id)
          expect(page).to have_current_path new_prison_case_information_path('LEI', offender_id)
        end

        it 'complains if the user does not select any radio buttons', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_missing_all } do
          click_button 'Continue'
          expect(CaseInformation.count).to eq(0)
          expect(page).to have_content(error_msg)
        end

        it 'complains if the user selects the yes radio button, but does not select a country',
           :raven_intercept_exception,
           vcr: { cassette_name: :case_information_missing_country } do
          choose('last_known_location_yes')
          click_button 'Continue'
          expect(CaseInformation.count).to eq(0)
          expect(page).to have_content(error_msg)
        end
      end

      it 'can set case information for a Scottish or Northern Irish offender', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_scotland_and_ni } do
        countries = ['Northern Ireland', 'Scotland']
        offenders = [nomis_offender_id, other_nomis_offender_id]
        signin_user

        countries.each_with_index do |country, index|
          visit prison_summary_pending_path('LEI')

          within "#edit_#{offenders[index]}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', offenders[index])
          choose_country(country: country)

          expect { click_button 'Continue' }.to change(enqueued_jobs, :size).by(0)
          expect(page).not_to have_css(".notification")
          expect(page).not_to have_css(".alert")
          expect(current_url).to have_content "/prisons/LEI/summary/pending"
          expect(page).to have_css('.offender_row_0', count: 1)
        end

        group_expectations(probation_services: ['Northern Ireland', 'Scotland'], tiers: %w[N/A N/A], teams: [nil, nil], case_allocs: %w[N/A N/A])
      end
    end

    context "when the offender is Welsh or considered English", js: true do
      it 'shows error messages when second page of form not filled', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_error_messages } do
        signin_user
        visit prison_summary_pending_path('LEI')
        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_country(country: "England")
        click_button('Continue')

        # attempt to save form without filling in the additional fields
        click_button('Continue')

        expect(page).to have_content("Select the service provider")
        expect(page).to have_content("Select the prisoner's tier")
        expect(page).to have_content("You must select the prisoner's team")
        expect(CaseInformation.count).to eq(0)
      end

      context 'when form saved' do
        before do
          allow(Nomis::Elite2::UserApi).to receive(:user_details).with("MOIC_POM").and_return(user_details)
          DeliusImportError.create(nomis_offender_id: nomis_offender_id, error_type: DeliusImportError::DUPLICATE_NOMIS_ID)

          signin_user
          visit prison_summary_pending_path('LEI')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end
          visit new_prison_case_information_path('LEI', nomis_offender_id)
        end

        it 'enqueue emails to LDU and SPO when email addresses present',
           vcr: { cassette_name: :case_information_send_emails_to_ldu_and_spo } do
          choose_country(country: 'England')
          click_button 'Continue'

          second_page_form(case_alloc: 'nps', tier: 'a', team_option: 'NPS - England')
          email_expectations(button_name: 'Continue',
                             emails: %w[EnglishNPS@example.com spo_user@digital-justice.uk],
                             spo_notice: 'This is a copy of the email sent to the LDU for your records',
                             expect_count: :twice)

          within ".notification" do
            expect(page).to have_content(notification_with_email)
          end
          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'NPS')
        end

        it 'when there is no LDU email address, send email to SPO only',
           vcr: { cassette_name: :case_information_no_ldu_email } do
          choose_country(country: 'England')
          click_button 'Continue'

          second_page_form(case_alloc: 'nps', tier: 'a', team_option: 'NPS - England 2')
          email_expectations(button_name: 'Continue',
                             emails: %w[spo_user@digital-justice.uk],
                             spo_notice: "We were unable to send an email to English LDU 2 as we do not have their "\
                                            "email address. You need to find another way to provide them with this "\
                                            "information.",
                             expect_count: :once)

          within ".notification" do
            expect(page).to have_content(notification_with_email)
          end

          within ".alert" do
            expect(page).to have_content("An email could not be sent to the community probation team - English LDU 2 "\
                                         "because there is no email address saved. You need to find an alternative way"\
                                         " to contact them.")
          end

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England 2', case_allocation: 'NPS')
        end

        it 'when there is no SPO email address, send email to LDU only', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_spo_email } do
          choose_country(country: 'England')
          click_button 'Continue'

          second_page_form(case_alloc: 'nps', tier: 'a', team_option: 'NPS - England')
          user_details.email_address = []

          expect {
            click_button 'Continue'
          }.to change(enqueued_jobs, :size).by(1)

          within ".notification" do
            expect(page).to have_content(notification_with_email)
          end

          within ".alert" do
            expect(page).to have_content("We could not send you an email because there is no valid email address "\
                                         "saved to your account. You need to contact the local system administrator "\
                                         "in your prison to update your email address.")
          end

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'NPS')
        end

        it 'when there are no email addresses for LDU or SPO, no email sent', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_ldu_or_spo_email } do
          choose_country(country: 'England')
          click_button 'Continue'

          second_page_form(case_alloc: 'nps', tier: 'a', team_option: 'NPS - England 2')
          user_details.email_address = []

          expect {
            click_button 'Continue'
          }.to change(enqueued_jobs, :size).by(0)

          within ".notification" do
            expect(page).to have_content(notification_without_email)
          end

          within ".alert" do
            expect(page).to have_content("An email could not be sent to the community probation team - English LDU 2 "\
                                         "because there is no email address saved. You need to find an alternative "\
                                         "way to contact them. We could not send you an email because there is no "\
                                         "valid email address saved to your account. You need to contact the "\
                                         "local system administrator in your prison to update your email address.")
          end

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England 2', case_allocation: 'NPS')
        end
      end
    end
  end

  context 'when updating an offenders case information', js: true do
    context 'when offender is Scottish or Northern Irish' do
      it 'can be changed to England or Wales', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_when_scottish_or_ni } do
        old_countries = ['Northern Ireland', 'Scotland']
        new_countries = %w[England Wales]
        offenders = [nomis_offender_id, other_nomis_offender_id]
        signin_user

        old_countries.each_with_index do |country, index|
          visit new_prison_case_information_path('LEI', offenders[index])
          choose_country(country: country)
          click_button 'Continue'

          visit edit_prison_case_information_path('LEI', offenders[index])
          expect(page).not_to have_css("div.optional-case-info")

          if new_countries[index] == 'England'
            choose('case_information_last_known_location_no', visible: false)
            second_page_form(case_alloc: 'crc', tier: 'd', team_option: 'NPS - England')
          else
            choose('case_information_probation_service_wales', visible: false)
            second_page_form(case_alloc: 'nps', tier: 'b', team_option: 'NPS - Wales')
          end

          click_button 'Update'
        end

        group_expectations(probation_services: %w[England Wales], tiers: %w[D B],
                           teams: ['NPS - England', 'NPS - Wales'], case_allocs: %w[CRC NPS])
      end

      it 'complains if tier, case_allocation or team not selected when changing to England or Wales',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_validation_errors } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_country(country: 'Scotland')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('case_information_last_known_location_no', visible: false)

        expect(page).to have_css("div.optional-case-info")
        click_button 'Update'

        expect(page).to have_content("You must select the prisoner's team")
        expect(page).to have_content("Select the prisoner's tier")
        expect(page).to have_content("Select the service provider for this case")
        expectations(probation_service: 'Scotland', tier: 'N/A', team: nil, case_allocation: 'N/A')
      end
    end

    context "when the prisoner is from England or Wales" do
      it 'can be changed to Scotland, Wales or NI',
         vcr: { cassette_name: :case_information_update_change_country } do
        old_countries = %w[England Wales]
        offenders = [nomis_offender_id, other_nomis_offender_id]
        signin_user

        old_countries.each_with_index do |country, index|
          visit new_prison_case_information_path('LEI', offenders[index])
          choose_country(country: country)
          click_button 'Continue'

          if country == 'England'
            second_page_form(case_alloc: 'nps', tier: 'c', team_option: 'NPS - England')
          else
            second_page_form(case_alloc: 'crc', tier: 'd', team_option: 'NPS - Wales')
          end
          click_button 'Continue'
          visit edit_prison_case_information_path('LEI', offenders[index])
          expect(page).to have_css("div.optional-case-info")

          if country == 'England'
            choose_country(country: 'Scotland')
          else
            choose_country(country: 'England')
            second_page_form(case_alloc: 'crc', tier: 'a', team_option: 'NPS - England')
          end
          click_button 'Update'
        end

        group_expectations(probation_services: %w[Scotland England], tiers: %w[N/A A], teams: [nil, 'NPS - England'], case_allocs: %w[N/A CRC])
      end

      it 'complains if country not selected when changing to another country', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_location_validation_errors } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_country(country: 'England')
        click_button 'Continue'
        second_page_form(case_alloc: 'crc', tier: 'd', team_option: 'NPS - England')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('last_known_location_yes', visible: false)
        click_button 'Update'

        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, "\
                                    "Scotland or Wales")
        expectations(probation_service: 'England', tier: 'D', team: 'NPS - England', case_allocation: 'CRC')
      end
    end

    context "when submitting form enqueue emails" do
      before do
        allow(Nomis::Elite2::UserApi).to receive(:user_details).with("MOIC_POM").and_return(user_details)
        DeliusImportError.create(nomis_offender_id: nomis_offender_id,
                                 error_type: DeliusImportError::DUPLICATE_NOMIS_ID)

        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
      end

      it 'does not send email if team_id has not been updated',
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_team_not_changed } do
        choose_country(country: 'Wales')
        click_button 'Continue'
        second_page_form(case_alloc: 'nps', tier: 'b', team_option: 'NPS - Wales')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('case_information_tier_c', visible: false)

        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)

        expect(page).not_to have_css(".notification")
        expect(page).not_to have_css(".alert")
        expectations(probation_service: 'Wales', tier: 'C', team: 'NPS - Wales', case_allocation: 'NPS')
      end

      it 'does not send email if probation_service changed to Scotland or Northern Ireland', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_probation_scotland_or_ni } do
        choose_country(country: 'Wales')
        click_button 'Continue'
        second_page_form(case_alloc: 'nps', tier: 'b', team_option: 'NPS - Wales')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_country(country: 'Northern Ireland')

        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)
        expect(page).not_to have_css(".notification")
        expect(page).not_to have_css(".alert")
      end

      it 'does not send email when updating team has the same ldu', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_updated_team_has_same_ldu } do
        choose_country(country: 'England')
        click_button 'Continue'
        second_page_form(case_alloc: 'nps', tier: 'b', team_option: 'NPS - England')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 3'")

        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)

        expect(page).not_to have_css(".notification")
        expect(page).not_to have_css(".alert")
        expectations(probation_service: 'England', tier: 'B', team: 'NPS - England 3', case_allocation: 'NPS')
      end

      it 'will send an email when probation_service changed to England or Wales from Scotland or Northern Ireland',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_sent_when_probation_changed_from_scot_or_ni } do
        choose_country(country: 'Northern Ireland')
        click_button 'Continue'
        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        choose_country(country: 'Wales')
        second_page_form(case_alloc: 'crc', tier: 'b', team_option: 'NPS - Wales')

        email_expectations(button_name: 'Update',
                           emails: %w[WalesNPS@example.com spo_user@digital-justice.uk],
                           spo_notice: 'This is a copy of the email sent to the LDU for your records',
                           expect_count: :twice)

        within ".notification" do
          expect(page).to have_content(notification_with_email)
        end

        expect(page).not_to have_css(".alert")
        expectations(probation_service: 'Wales', tier: 'B', team: 'NPS - Wales', case_allocation: 'CRC')
      end

      it 'will send an email when updating team which has a different ldu', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_sent_when_updated_team_has_different_ldu } do
        choose_country(country: 'Wales')
        click_button 'Continue'
        second_page_form(case_alloc: 'crc', tier: 'd', team_option: 'NPS - Wales')
        click_button 'Continue'

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        choose_country(country: 'England')
        second_page_form(case_alloc: 'nps', tier: 'a', team_option: 'NPS - England 3')

        email_expectations(button_name: 'Update',
                           emails: %w[EnglishNPS@example.com spo_user@digital-justice.uk],
                           spo_notice: 'This is a copy of the email sent to the LDU for your records',
                           expect_count: :twice)

        within ".notification" do
          expect(page).to have_content(notification_with_email)
        end

        expect(page).not_to have_css(".alert")
        expectations(probation_service: 'England', tier: 'A', team: 'NPS - England 3', case_allocation: 'NPS')
      end
    end
  end

  it "clicking back link after viewing prisoner's case information, returns back the same paginated page",
     :raven_intercept_exception,
     vcr: { cassette_name: :case_information_back_link }, js: true do
    signin_user
    visit prison_summary_pending_path('LEI', page: 3)

    within ".govuk-table tr:first-child td:nth-child(5)" do
      click_link 'Edit'
    end
    expect(page).to have_selector('h1', text: 'Case information')

    click_link 'Back'
    expect(page).to have_selector('h1', text: 'Add missing information')
  end

  it 'returns to previously paginated page after saving', :raven_intercept_exception,
     vcr: { cassette_name: :case_information_return_to_previously_paginated_page } do
    signin_user
    visit prison_summary_pending_path('LEI', sort: "last_name desc", page: 3)

    within ".govuk-table tr:first-child td:nth-child(5)" do
      click_link 'Edit'
    end
    expect(page).to have_selector('h1', text: 'Case information')
    choose_country(country: 'Scotland')
    click_button 'Continue'
    expect(current_url).to have_content("/prisons/LEI/summary/pending?page=3&sort=last_name+desc")
  end

  it 'does not show update link on view only case info',
     vcr: { cassette_name: :case_information_no_update } do
    # When auto-delius is on there should be no update link to modify the case info
    # as it may not exist yet. We run this test with an indeterminate and a determine offender
    signin_user

    # Indeterminate offender
    offender_id = 'G0806GQ'
    visit prison_case_information_path('LEI', offender_id)
    expect(page).not_to have_css('#edit-prd-link')

    # Determinate offender
    visit prison_case_information_path('LEI', nomis_offender_id)
    expect(page).not_to have_css('#edit-prd-link')
  end

  def expectations(probation_service:, tier:, team:, case_allocation:)
    expect(CaseInformation.first.probation_service).to eq(probation_service)
    expect(CaseInformation.first.tier).to eq(tier)
    if team.nil?
      expect(CaseInformation.first.team).to eq(nil)
    else
      expect(CaseInformation.first.team.name).to eq(team)
    end
    expect(CaseInformation.first.case_allocation).to eq(case_allocation)
  end

  def email_expectations(button_name:, emails:, spo_notice:, expect_count:)
    expect {
      click_button button_name
    }.to have_enqueued_job(CaseAllocationEmailJob).with { |**args|
      expect(args).to include(email: emails.first, notice: '') |
                      include(email: emails.last,
                              notice: spo_notice)
    }.exactly(expect_count)
  end

  def group_expectations(probation_services:, tiers:, teams:, case_allocs:)
    expect(CaseInformation.first.probation_service).to eq(probation_services.first)
    if CaseInformation.first.team.nil?
      expect(CaseInformation.first.team).to eq(nil)
    else
      expect(CaseInformation.first.team.name).to eq(teams.first)
    end
    expect(CaseInformation.first.case_allocation).to eq(case_allocs.first)
    expect(CaseInformation.first.tier).to eq(tiers.first)
    expect(CaseInformation.last.probation_service).to eq(probation_services.last)

    if CaseInformation.last.team.nil?
      expect(CaseInformation.last.team).to eq(nil)
    else
      expect(CaseInformation.last.team.name).to eq(teams.last)
    end
    expect(CaseInformation.last.case_allocation).to eq(case_allocs.last)
    expect(CaseInformation.last.tier).to eq(tiers.last)
  end

  def second_page_form(case_alloc:, tier:, team_option:)
    choose("case_information_case_allocation_#{case_alloc}", visible: false) unless case_alloc.nil?
    choose("case_information_tier_#{tier}", visible: false) unless tier.nil?
    page.execute_script("document.getElementsByName('input-autocomplete')[0].value='#{team_option}'")
  end

  def choose_country(country:)
    if country == 'England'
      choose('case_information_last_known_location_no', visible: false)
    else
      choose('last_known_location_yes', visible: false)
      area = country.downcase.tr(" ", "_")
      probation = "case_information_probation_service_" + area
      choose(probation, visible: false)
    end
  end
end
