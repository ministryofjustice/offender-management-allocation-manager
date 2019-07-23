require 'rails_helper'

# TODO: The case information editing feature will presumably come back when we add parole_review_date
xfeature 'case information feature' do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:auto_delius_import, true)
  end
  it 'adds tiering and case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)

    choose('case_information_omicable_Yes')
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

  xit 'allows editing case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_editing_feature } do
    nomis_offender_id = 'G1821VA'

    signin_user
    visit new_prison_case_information_path('LEI', nomis_offender_id)
    choose('case_information_omicable_No')
    choose('case_information_case_allocation_NPS')
    choose('case_information_tier_A')
    click_button 'Save'

    visit edit_prison_case_information_path('LEI', nomis_offender_id)

    expect(page).to have_content('Case information')
    expect(page).to have_content('G1821VA')
    choose('case_information_omicable_No')
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
