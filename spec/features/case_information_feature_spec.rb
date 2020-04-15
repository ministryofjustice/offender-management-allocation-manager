require 'rails_helper'

feature 'case information feature' do
  include ActiveJob::TestHelper
  before do
    [
      LocalDivisionalUnit.create!(code: "WELDU", name: "Welsh LDU", email_address: "WalesNPS@example.com"),
      LocalDivisionalUnit.create!(code: "ENLDU", name: "English LDU", email_address: "EnglishNPS@example.com"),
      LocalDivisionalUnit.create!(code: "OTHERLDU", name: "English LDU 2", email_address: nil),
      Team.create!(code: "WELSH1", name: 'NPS - Wales', shadow_code: "W01", local_divisional_unit_id: 1),
      Team.create!(code: "ENG1", name: 'NPS - England', shadow_code: "E01", local_divisional_unit_id: 2),
      Team.create!(code: "ENG2", name: 'NPS - England 2', shadow_code: "E02", local_divisional_unit_id: 3),
      Team.create!(code: "ENG3", name: 'NPS - England 3', shadow_code: "E03", local_divisional_unit_id: 2)
    ]
  end

  # This NOMIS id needs to appear on the first page of 'missing information'
  let(:nomis_offender_id) { 'G2911GD' }

  context 'when creating case information' do
    context "when the prisoner's last known location is in Scotland or Northern Ireland" do
      it 'complains if the user does not select any radio buttons', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_all } do
        nomis_offender_id = 'G1821VA' # different nomis offender no

        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

        click_button 'Continue'

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, "\
                                      "Scotland or Wales")
      end

      it 'complains if the user selects the yes radio button, but does not select a country',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_country } do
        nomis_offender_id = 'G1821VA' # different nomis offender no
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

        choose('last_known_location_yes')
        click_button 'Continue'

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, "\
                                      "Scotland or Wales")
      end

      it 'can set case information for a Scottish offender', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_scottish } do
        signin_user

        visit prison_summary_pending_path('LEI')
        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_scotland

        expectations(probation_service: 'Scotland', tier: 'N/A', team: nil, case_allocation: 'N/A')
        expect(current_url).to have_content "/prisons/LEI/summary/pending"
        expect(page).to have_css('.offender_row_0', count: 1)
      end

      it 'can set case information for a Northern Irish offender', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_northern_irish } do
        signin_user

        visit prison_summary_pending_path('LEI')
        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_northern_ireland

        expectations(probation_service: 'Northern Ireland', tier: 'N/A', team: nil, case_allocation: 'N/A')
        expect(current_url).to have_content "/prisons/LEI/summary/pending"
        expect(page).to have_css('.offender_row_0', count: 1)
      end

      it 'does not sent emails to LDU or SPO', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_ni_no_emails } do
        signin_user

        visit prison_summary_pending_path('LEI')
        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose('last_known_location_yes', visible: false)
        choose('case_information_probation_service_northern_ireland', visible: false)
        expect{
          click_button 'Continue'
        }.to change(enqueued_jobs, :size).by(0)
      end
    end

    context "when the prisoner's last known location is in England or Wales", js: true do
      it 'adds tier, service provider and team for English prisoner', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_english } do
        signin_user

        visit prison_summary_pending_path('LEI')

        expect(page).to have_content('Update information')
        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_a',
                       team_option: 'NPS - England')

        expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'NPS')
        expect(current_url).to have_content "/prisons/LEI/summary/pending"
        expect(page).to have_css('.offender_row_0', count: 1)
      end

      it 'adds tier, service provider and team for Welsh prisoner', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_welsh } do
        signin_user
        visit prison_summary_pending_path('LEI')

        expect(page).to have_content('Update information')
        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(case_alloc: 'case_information_case_allocation_crc', tier: 'case_information_tier_d',
                     team_option: 'NPS - Wales')

        expectations(probation_service: 'Wales', tier: 'D', team: 'NPS - Wales', case_allocation: 'CRC')
        expect(current_url).to have_content "/prisons/LEI/summary/pending"
        expect(page).to have_css('.offender_row_0', count: 1)
      end

      it 'complains if service provider has not been selected', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_service_provider } do
        signin_user
        visit prison_summary_pending_path('LEI')
        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(case_alloc: nil, tier: 'case_information_tier_a', team_option: 'NPS - England 2')

        expect(page).to have_content("Select the service provider for this case")
        expect(CaseInformation.count).to eq(0)
      end

      it 'complains if tier has not been selected', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_tier } do
        signin_user
        visit prison_summary_pending_path('LEI')

        expect(page).to have_content('Update information')
        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(case_alloc: 'case_information_case_allocation_nps', tier: nil, team_option: 'NPS - England 2')

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("Select the prisoner's tier")
      end

      it 'complains if team has not been selected', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_team } do
        signin_user
        visit prison_summary_pending_path('LEI')

        expect(page).to have_content('Update information')

        within "#edit_#{nomis_offender_id}" do
          click_link 'Edit'
        end

        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_a',
                       team_option: "")

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("You must select the prisoner's team")
      end

      context 'when submitting form enqueue emails' do
        let(:user_details) do
          user = Nomis::UserDetails.new
          user.staff_id = 423_142
          user.first_name = "JOHN"
          user.last_name = "SMITH"
          user.status = "ACTIVE"
          user.thumbnail_id = 231_232
          user.username = "PK000223"
          user.email_address = ['spo_user@digital-justice.uk']
          user
        end

        before do
          allow(Nomis::Elite2::UserApi).to receive(:user_details).with("PK000223").and_return(user_details)
          DeliusImportError.create(nomis_offender_id: nomis_offender_id,
                                   error_type: DeliusImportError::DUPLICATE_NOMIS_ID)
        end

        it 'when LDU and SPO email addresses are present, it sends email to both',
           :raven_intercept_exception, vcr: { cassette_name: :case_information_send_emails_to_ldu_and_spo } do
          signin_user

          visit prison_summary_pending_path('LEI')

          expect(page).to have_content('Update information')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', nomis_offender_id)
          choose('case_information_last_known_location_no', visible: false)
          click_button 'Continue'
          choose('case_information_case_allocation_nps', visible: false)
          choose('case_information_tier_a', visible: false)

          page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England'")

          expect {
            click_button 'Continue'
          }.to have_enqueued_job(CaseAllocationEmailJob).with { |**args|
            expect(args).to include(email: "EnglishNPS@example.com", notice: "") |
                            include(email: "spo_user@digital-justice.uk",
                                    notice: 'This is a copy of the email sent to the LDU for your records')
          }.exactly(:twice)

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'NPS')
        end

        it 'when there is no LDU email address, send email to SPO only', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_ldu_email } do
          signin_user
          visit prison_summary_pending_path('LEI')

          expect(page).to have_content('Update information')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', nomis_offender_id)
          choose('case_information_last_known_location_no', visible: false)
          click_button 'Continue'
          choose('case_information_case_allocation_nps', visible: false)
          choose('case_information_tier_a', visible: false)
          page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 2'")

          expect {
            click_button 'Continue'
          }.to have_enqueued_job(CaseAllocationEmailJob).with { |**args|
            expect(args).to include(email: "spo_user@digital-justice.uk",
                                    notice: "We were unable to send an email to English LDU 2 as we do not have their "\
                                            "email address. You need to find another way to provide them with this "\
                                            "information.")
          }.exactly(:once)

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England 2', case_allocation: 'NPS')
        end

        it 'when there is no SPO email address, send email to LDU only', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_spo_email } do
          signin_user
          visit prison_summary_pending_path('LEI')

          expect(page).to have_content('Update information')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', nomis_offender_id)
          choose('case_information_last_known_location_no', visible: false)
          click_button 'Continue'
          choose('case_information_case_allocation_nps', visible: false)
          choose('case_information_tier_a', visible: false)
          page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England'")

          user_details.email_address = []

          expect {
            click_button 'Continue'
          }.to change(enqueued_jobs, :size).by(1)

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'NPS')
        end

        it 'when there are no email addresses for LDU or SPO, no email sent', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_ldu_or_spo_email } do
          signin_user
          visit prison_summary_pending_path('LEI')

          expect(page).to have_content('Update information')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', nomis_offender_id)
          choose('case_information_last_known_location_no', visible: false)
          click_button 'Continue'
          choose('case_information_case_allocation_nps', visible: false)
          choose('case_information_tier_a', visible: false)
          page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 2'")

          user_details.email_address = []

          expect {
            click_button 'Continue'
          }.to change(enqueued_jobs, :size).by(0)

          expectations(probation_service: 'England', tier: 'A', team: 'NPS - England 2', case_allocation: 'NPS')
        end

        it 'does not sent email if form has errors', :raven_intercept_exception,
           vcr: { cassette_name: :case_information_no_email_sent_with_form_errors } do
          signin_user
          visit prison_summary_pending_path('LEI')

          expect(page).to have_content('Update information')
          within "#edit_#{nomis_offender_id}" do
            click_link 'Edit'
          end

          visit new_prison_case_information_path('LEI', nomis_offender_id)
          choose('case_information_last_known_location_no', visible: false)
          click_button 'Continue'
          choose('case_information_case_allocation_nps', visible: false)
          page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 2'")

          expect {
            click_button 'Continue'
          }.to change(enqueued_jobs, :size).by(0)

          expect(page).to have_content("Select the prisoner's tier")
        end
      end
    end
  end

  context 'when editing case information', js: true do
    context "when prisoner's last known location is in Scotland or Northern Ireland" do
      it 'hides tier/team and service provider', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_hide_optional_case_info } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_scotland

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        expect(page).to have_content(nomis_offender_id)
        expect(page).not_to have_css("div.optional-case-info")
      end
    end

    context "when the prisoner's last known location is in England or Wales" do
      it 'shows tier/team and service provider', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_show_optional_case_info } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_england(case_alloc: 'case_information_case_allocation_nps',
                       tier: 'case_information_tier_a', team_option: 'NPS - England 2')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        expect(page).to have_content(nomis_offender_id)
        expect(page).to have_css("div.optional-case-info")
        expect(page).to have_css("#chosen_team", text: 'NPS - England 2')
      end
    end
  end

  context 'when updating a prisoners case information', js: true do
    context "when prisoner is from Scotland or Northern Ireland" do
      it 'can change last known location in Scotland to Wales', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_from_scotland_to_wales } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_scotland

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(false, case_alloc: 'case_information_case_allocation_nps',
                            tier: 'case_information_tier_b', team_option: 'NPS - Wales')

        expectations(probation_service: 'Wales', tier: 'B', team: 'NPS - Wales', case_allocation: 'NPS')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'can change last known location from Northern Ireland to England', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_from_ni_to_england } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_northern_ireland

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(false, case_alloc: 'case_information_case_allocation_crc',
                              tier: 'case_information_tier_d', team_option: 'NPS - England')

        expectations(probation_service: 'England', tier: 'D', team: 'NPS - England', case_allocation: 'CRC')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'can change last known location from Northern Ireland to Wales', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_from_ni_to_wales } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_northern_ireland

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(false, case_alloc: 'case_information_case_allocation_crc',
                            tier: 'case_information_tier_d', team_option: 'NPS - Wales')

        expectations(probation_service: 'Wales', tier: 'D', team: 'NPS - Wales', case_allocation: 'CRC')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'complains if tier, case_allocation or team not selected when changing to England or Wales',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_validation_errors } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_scotland

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
      it 'can change last known location from England to Scotland', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_from_england_to_scotland }  do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_england(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_c',
                       team_option: 'NPS - England')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_scotland(false)

        expectations(probation_service: 'Scotland', tier: 'N/A', team: nil, case_allocation: 'N/A')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'from last known location in Wales to England', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_from_wales_to_england } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_b',
                     team_option: 'NPS - Wales')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(false, case_alloc: 'case_information_case_allocation_crc',
                              tier: 'case_information_tier_a', team_option: 'NPS - England')

        expectations(probation_service: 'England', tier: 'A', team: 'NPS - England', case_allocation: 'CRC')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'complains if country not selected when changing to another country', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_location_validation_errors } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)

        choose_england(case_alloc: 'case_information_case_allocation_crc', tier: 'case_information_tier_d',
                       team_option: 'NPS - England')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('last_known_location_yes', visible: false)
        click_button 'Update'

        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, "\
                                    "Scotland or Wales")
        expectations(probation_service: 'England', tier: 'D', team: 'NPS - England', case_allocation: 'CRC')
      end
    end

    context "when submitting form enqueue emails" do
      let(:user_details) do
        user = Nomis::UserDetails.new
        user.staff_id = 423_142
        user.first_name = "JOHN"
        user.last_name = "SMITH"
        user.status = "ACTIVE"
        user.thumbnail_id = 231_232
        user.username = "PK000223"
        user.email_address = ['spo_user@digital-justice.uk']
        user
      end

      before do
        allow(Nomis::Elite2::UserApi).to receive(:user_details).with("PK000223").and_return(user_details)
        DeliusImportError.create(nomis_offender_id: nomis_offender_id,
                                 error_type: DeliusImportError::DUPLICATE_NOMIS_ID)
      end

      it 'does not send email if team_id has not been updated', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_team_not_changed } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_b',
                     team_option: 'NPS - Wales')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('case_information_tier_c', visible: false)
        page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - Wales'")

        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)

        expectations(probation_service: 'Wales', tier: 'C', team: 'NPS - Wales', case_allocation: 'NPS')
        expect(current_url).to have_content "/prisons/LEI/allocations/#{nomis_offender_id}/new"
      end

      it 'does not send email if probation_service changed to Scotland or Northern Ireland', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_probation_scotland_or_ni } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_b',
                     team_option: 'NPS - Wales')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)
        choose('last_known_location_yes', visible: false)
        choose('case_information_probation_service_northern_ireland', visible: false)
        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)
      end

      it 'does not send email when updating team has the same ldu', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_not_triggered_when_updated_team_has_same_ldu } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_england(case_alloc: 'case_information_case_allocation_nps', tier: 'case_information_tier_b',
                       team_option: 'NPS - England')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 3'")

        expect {
          click_button 'Update'
        }.to change(enqueued_jobs, :size).by(0)

        expectations(probation_service: 'England', tier: 'B', team: 'NPS - England 3', case_allocation: 'NPS')
      end

      it 'will send an email when probation_service changed to England or Wales from Scotland or Northern Ireland',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_sent_when_probation_changed_from_scot_or_ni } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_northern_ireland

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        choose('last_known_location_yes', visible: false)
        choose('case_information_probation_service_wales', visible: false)
        choose('case_information_case_allocation_crc', visible: false)
        choose('case_information_tier_b', visible: false)
        page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - Wales'")

        expect{
          click_button 'Update'
        }.to have_enqueued_job(CaseAllocationEmailJob).with { |**args|
          expect(args).to include(email: "WalesNPS@example.com", notice: "") |
                          include(email: "spo_user@digital-justice.uk",
                                  notice: 'This is a copy of the email sent to the LDU for your records')
        }.exactly(:twice)

        expectations(probation_service: 'Wales', tier: 'B', team: 'NPS - Wales', case_allocation: 'CRC')
      end

      it 'will send an email when updating team which has a different ldu', :raven_intercept_exception,
         vcr: { cassette_name: :case_information_update_email_sent_when_updated_team_has_different_ldu } do
        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        choose_wales(case_alloc: 'case_information_case_allocation_crc', tier: 'case_information_tier_d',
                     team_option: 'NPS - Wales')

        visit edit_prison_case_information_path('LEI', nomis_offender_id)

        choose('case_information_last_known_location_no', visible: false)
        choose('case_information_case_allocation_nps', visible: false)
        choose('case_information_tier_a', visible: false)
        page.execute_script("document.getElementsByName('input-autocomplete')[0].value='NPS - England 3'")

        expect{
          click_button('Update')
        }.to have_enqueued_job(CaseAllocationEmailJob).with { |**args|
          expect(args).to include(email: "EnglishNPS@example.com", notice: "") |
                          include(email: "spo_user@digital-justice.uk",
                                  notice: 'This is a copy of the email sent to the LDU for your records')
        }.exactly(:twice)

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
    choose_scotland
    expect(current_url).to have_content("/prisons/LEI/summary/pending?page=3&sort=last_name+desc")
  end

  it 'does not show update link on view only case info', :raven_intercept_exception,
     vcr: { cassette_name: :case_information_no_update } do
    # When auto-delius is on there should be no update link to modify the case info
    # as it may not exist yet. We run this test with an indeterminate and a determine offender
    signin_user

    # Indeterminate offender
    nomis_offender_id = 'G0806GQ'
    visit prison_case_information_path('LEI', nomis_offender_id)
    expect(page).not_to have_css('#edit-prd-link')

    # Determinate offender
    nomis_offender_id = 'G2911GD'
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

  def choose_northern_ireland
    choose('last_known_location_yes', visible: false)
    choose('case_information_probation_service_northern_ireland', visible: false)
    click_button 'Continue'
  end

  def choose_scotland(create_action = true)
    choose('last_known_location_yes', visible: false)
    choose('case_information_probation_service_scotland', visible: false)
    button_name = create_action ? 'Continue' : 'Update'
    click_button button_name
  end

  def choose_england(create_action = true, case_alloc:, tier:, team_option:)
    choose('case_information_last_known_location_no', visible: false)
    button_name = create_action ? 'Continue' : 'Update'
    click_button button_name if create_action

    choose(case_alloc, visible: false) unless case_alloc.nil?
    choose(tier, visible: false) unless tier.nil?
    page.execute_script("document.getElementsByName('input-autocomplete')[0].value='#{team_option}'")
    click_button button_name
  end

  def choose_wales(create_action = true, case_alloc:, tier:, team_option:)
    choose('last_known_location_yes', visible: false) if create_action
    choose('case_information_probation_service_wales', visible: false)
    button_name = create_action ? 'Continue' : 'Update'
    click_button button_name if create_action

    choose(case_alloc, visible: false) unless case_alloc.nil?
    choose(tier, visible: false) unless tier.nil?
    page.execute_script("document.getElementsByName('input-autocomplete')[0].value='#{team_option}'")
    click_button button_name
  end
end
