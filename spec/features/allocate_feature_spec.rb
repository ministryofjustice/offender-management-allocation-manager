require 'rails_helper'

feature 'Allocation' do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:prison_officer_nomis_staff_id) { 485_752 }
  let!(:nomis_offender_id) { 'G4273GI' }
  let!(:never_allocated_offender) { 'G1670VU' }

  let!(:probation_officer_pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }

  let!(:case_information) {
    CaseInformation.create!(nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', omicable: 'No', prison: 'LEI')
  }

  scenario 'accepting a recommended allocation', versioning: true, vcr: { cassette_name: :create_new_allocation_feature } do
    signin_user

    visit new_allocation_path(nomis_offender_id)

    expect(page).to have_content('Determinate')
    expect(page).to have_content('There is 1 POM unavailable for new allocations.')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Ozullirn Abbella to Ross Jones')

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_unallocated_path
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Ross Jones (Probation POM)')
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature_ok } do
    override_nomis_staff_id = 485_737

    signin_user

    visit new_allocation_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-2')
    check('override-3')
    click_button('Continue')

    expect(Override.count).to eq(1)

    expect(page).to have_current_path confirm_allocation_path(nomis_offender_id, override_nomis_staff_id)

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_unallocated_path
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Jay Heal (Prison POM)')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: :override_allocation_feature_validate_reasons } do
    signin_user

    visit new_allocation_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    click_button('Continue')
    expect(page).to have_content('Select one or more reasons for not accepting the recommendation')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing Other detail', vcr: { cassette_name: :override_allocation_feature_validate_other } do
    signin_user

    visit new_allocation_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-4')
    click_button('Continue')
    expect(page).to have_content('Please provide extra detail when Other is selected')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing suitabilitydetail', vcr: { cassette_name: :override_suitability_allocation_feature } do
    signin_user

    visit new_allocation_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-1')
    click_button('Continue')
    expect(page).to have_content('Enter reason for allocating this POM')
    expect(Override.count).to eq(0)
  end

  scenario 're-allocating', versioning: true, vcr: { cassette_name: :re_allocate_feature } do
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: probation_officer_nomis_staff_id
    )

    signin_user

    visit summary_allocated_path

    within('.allocated_offender_row_0') do
      click_link 'Reallocate'
    end

    expect(page).to have_current_path edit_allocation_path(nomis_offender_id)
    expect(page).to have_css('.current_pom_full_name', text: 'Duckett, Jenny')
    expect(page).to have_css('.current_pom_grade', text: 'Prison POM')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_current_path confirm_reallocation_path(nomis_offender_id, prison_officer_nomis_staff_id)

    click_button 'Complete allocation'

    expect(AllocationVersion.find_by(nomis_offender_id: nomis_offender_id).event).to eq("reallocate_primary_pom")
  end

  scenario 'allocation fails', vcr: { cassette_name: :allocation_fails_feature } do
    allow(AllocationService).to receive(:create_or_update).and_return(false)

    signin_user

    visit new_allocation_path(nomis_offender_id)

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_unallocated_path
    expect(page).to have_css(
      '.alert',
      text: 'Ozullirn Abbella has not been allocated - please try again'
    )
  end

  scenario 'cannot reallocate a non-allocated offender', vcr: { cassette_name: :allocation_attempt_bad_reallocate } do
    signin_user

    visit edit_allocation_path(never_allocated_offender)
    expect(page).to have_current_path new_allocation_path(never_allocated_offender)
  end

  scenario 'view allocation history for an offender', versioning: true, vcr: { cassette_name: :view_allocation_history } do
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: probation_officer_nomis_staff_id
    )

    signin_user
    visit allocation_history_path(nomis_offender_id)

    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)
    formatted_date = allocation.primary_pom_allocated_at.strftime("#{allocation.primary_pom_allocated_at.day.ordinalize} %B %Y")

    expect(page).to have_css('h1', text: "Abbella, Ozullirn")
    expect(page).to have_css('p', text: "Prisoner allocated to #{allocation.primary_pom_name.titlecase} Tier: #{allocation.allocated_at_tier}")
    expect(page).to have_css('.time', text: "#{formatted_date} by #{allocation.created_by_name}")
  end
end
