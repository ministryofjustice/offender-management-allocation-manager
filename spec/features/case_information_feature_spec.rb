require 'rails_helper'

feature 'case information feature' do
  it 'adds tiering and case information for a prisoner', :raven_intercept_exception, vcr: { cassette_name: :case_information_feature } do
    nomis_offender_id = 'G4273GI'

    signin_user
    visit summary_path

    within('#awaiting-information') do
      within('.offender_row_0') do
        click_link 'Edit'
      end
    end

    expect(page).to have_current_path new_case_information_path(nomis_offender_id)

    choose('case_information_case_allocation_NPS')
    choose('case_information_tier_A')
    click_button 'Save'

    expect(CaseInformation.count).to eq(1)
    expect(CaseInformation.first.nomis_offender_id).to eq(nomis_offender_id)
    expect(CaseInformation.first.tier).to eq('A')
    expect(CaseInformation.first.case_allocation).to eq('NPS')
    expect(page).to have_current_path summary_path

    within('#awaiting-allocation') do
      expect(page).to have_css('.offender_row_0', count: 1)
    end
  end

  it 'complains if allocation data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_case_feature } do
    nomis_offender_id = 'G4273GI'

    signin_user
    visit summary_path

    within('#awaiting-information') do
      within('.offender_row_0') do
        click_link 'Edit'
      end
    end

    expect(page).to have_current_path new_case_information_path(nomis_offender_id)

    choose('case_information_tier_A')
    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Case allocation must be provided")
  end

  it 'complains if all data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_all_feature } do
    nomis_offender_id = 'G4273GI'

    signin_user
    visit summary_path

    within('#awaiting-information') do
      within('.offender_row_0') do
        click_link 'Edit'
      end
    end

    expect(page).to have_current_path new_case_information_path(nomis_offender_id)

    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Case allocation must be provided")
    expect(page).to have_content("Tier must be provided")
  end

  it 'complains if tier data is missing', :raven_intercept_exception, vcr: { cassette_name: :case_information_missing_tier_feature } do
    nomis_offender_id = 'G4273GI'

    signin_user
    visit summary_path

    within('#awaiting-information') do
      within('.offender_row_0') do
        click_link 'Edit'
      end
    end

    expect(page).to have_current_path new_case_information_path(nomis_offender_id)

    choose('case_information_case_allocation_NPS')
    click_button 'Save'

    expect(CaseInformation.count).to eq(0)
    expect(page).to have_content("Tier must be provided")
  end
end
