require 'rails_helper'

feature 'case information feature' do
  it 'adds tiering and case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_feature } do
    # This NOMIS id needs to appear on the first page of 'missing information'
    nomis_offender_id = 'G2911GD'

    signin_user
    visit prison_summary_pending_path('LEI')

    expect(page).to have_content('Update information')
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
    expect(page).to have_current_path prison_summary_pending_path('LEI')

    expect(page).to have_css('.offender_row_0', count: 1)
  end

  it "clicking back link after viewing prisoner's case information, returns back the same paginated page",
     vcr: { cassette_name: :case_information_back_link }, js: true do
    signin_user
    visit prison_summary_pending_path('LEI', page: 3)

    within ".govuk-table tr:first-child td:nth-child(6)" do
      click_link 'Edit'
    end
    expect(page).to have_selector('h1', text:'Case information')

    click_link 'Back'
    expect(page).to have_selector('h1', text:'Allocations')
  end

  it 'complains if allocation data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_case_feature } do
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

  it 'complains if all data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_all_feature } do
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

  it 'complains if tier data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_tier_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

    choose('case_information_case_allocation_NPS')
    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Select the prisoner’s tier")
  end

  it 'allows editing case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_editing_feature } do
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
end
