require 'rails_helper'

feature 'case information feature' do
  before do
    [
      LocalDivisionalUnit.create!(code: "WELDU", name: "Welsh LDU", email_address: "WalesNPS@example.com"),
      LocalDivisionalUnit.create!(code: "ENLDU", name: "English LDU", email_address: "EnglishNPS@example.com"),
      LocalDivisionalUnit.create!(code: "OTHERLDU", name: "English LDU 2", email_address: nil),
      Team.create!(code: "WELSH1", name: 'NPS - Wales', shadow_code: "W01", local_divisional_unit_id: 1),
      Team.create!(code: "ENG1", name: 'NPS - England', shadow_code: "E01", local_divisional_unit_id: 2),
      Team.create!(code: "ENG2", name: 'NPS - England 2', shadow_code: "E02", local_divisional_unit_id: 3)
    ]
  end

  # This NOMIS id needs to appear on the first page of 'missing information'
  let(:nomis_offender_id) { 'G2911GD' }

  context 'when creating case information' do
    context "when the prisoner's last known address is in Scotland or Northern Ireland" do
      it 'complains if the user does not select any radio buttons', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_all_feature } do
        nomis_offender_id = 'G1821VA' # different nomis offender no

        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

        click_button 'Continue'

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales")
      end

      it 'complains if the user selects the yes radio button, but does not select a country',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_missing_country_feature } do
        nomis_offender_id = 'G1821VA' # different nomis offender no

        signin_user
        visit new_prison_case_information_path('LEI', nomis_offender_id)
        expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

        choose('last_known_location_yes')
        click_button 'Continue'

        expect(CaseInformation.count).to eq(0)
        expect(page).to have_content("You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales")
      end

      it 'can set case information for a Scottish offender',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_scottish_feature } do
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

      it 'can set case information for a Northern Irish offender',
         :raven_intercept_exception,
         vcr: { cassette_name: :case_information_northern_irish_feature } do
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
    end
  end

  xit 'adds tiering and case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_feature } do
    # This NOMIS id needs to appear on the first page of 'missing information'
    nomis_offender_id = 'G2911GD'

    signin_user
    visit prison_summary_pending_path('LEI')

    expect(page).to have_content('Add missing information')
    within "#edit_#{nomis_offender_id}" do
      click_link 'Edit'
    end
    visit new_prison_case_information_path('LEI', nomis_offender_id)

    choose('case_information_welsh_offender_Yes')
    choose('case_information_case_allocation_NPS')
    choose('case_information_tier_A')
    click_button 'Save'

    expect(CaseInformation.count).to eq(1)
    expect(CaseInformation.first.nomis_offender_id).to eq(nomis_offender_id)
    expect(CaseInformation.first.tier).to eq('A')
    expect(CaseInformation.first.case_allocation).to eq('NPS')
    expect(current_url).to have_content "/prisons/LEI/summary/pending"

    expect(page).to have_css('.offender_row_0', count: 1)
  end

  xit "clicking back link after viewing prisoner's case information, returns back the same paginated page",
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

  xit 'complains if allocation data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_case_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

    choose('case_information_tier_A')
    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Select the service provider for this case")
    expect(page).to have_content("Select yes if the prisoner’s last known address was in Wales")
  end

  xit 'complains if all data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_all_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Select the service provider for this case")
    expect(page).to have_content("Select the prisoner’s tier")
    expect(page).to have_content("Select yes if the prisoner’s last known address was in Wales")
  end

  xit 'complains if tier data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_tier_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

    choose('case_information_case_allocation_NPS')
    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Select the prisoner’s tier")
  end

  xit 'allows editing case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_editing_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    choose('case_information_welsh_offender_No')
    choose('case_information_case_allocation_NPS')
    choose('case_information_tier_A')
    click_button 'Save'

    visit edit_prison_case_information_path('LEI', nomis_offender_id)

    expect(page).to have_content('Case information')
    expect(page).to have_content('G1821VA')
    choose('case_information_welsh_offender_No')
    choose('case_information_case_allocation_CRC')
    click_button 'Update'

    expect(CaseInformation.count).to eq(1)
    expect(CaseInformation.first.nomis_offender_id).to eq(nomis_offender_id)
    expect(CaseInformation.first.tier).to eq('A')
    expect(CaseInformation.first.case_allocation).to eq('CRC')

    expect(page).to have_current_path new_prison_allocation_path('LEI', nomis_offender_id)
    expect(page).to have_content('CRC')
  end

  xit 'returns to previously paginated page after saving',
      vcr: { cassette_name: :case_information_return_to_previously_paginated_page } do
    signin_user
    visit prison_summary_pending_path('LEI', sort: "last_name desc", page: 3)

    within ".govuk-table tr:first-child td:nth-child(5)" do
      click_link 'Edit'
    end
    expect(page).to have_selector('h1', text: 'Case information')

    choose('case_information_welsh_offender_No')
    choose('case_information_case_allocation_NPS')
    choose('case_information_tier_A')
    click_button 'Save'

    expect(current_url).to have_content("/prisons/LEI/summary/pending?page=3&sort=last_name+desc")
  end

  it 'does not show update link on view only case info', :raven_intercept_exception,
     vcr: { cassette_name: :case_information_no_update_feature } do
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

  def choose_scotland
    choose('last_known_location_yes', visible: false)
    choose('case_information_probation_service_scotland', visible: false)
    click_button 'Continue'
  end
end
