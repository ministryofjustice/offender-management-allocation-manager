require 'rails_helper'

feature 'Allocation' do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:prison_officer_nomis_staff_id) { 485_752 }
  let!(:nomis_offender_id) { 'G4273GI' }

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

  scenario 'accepting a recommended allocation', vcr: { cassette_name: :create_new_allocation_feature } do
    signin_user

    visit new_allocations_path(nomis_offender_id)

    expect(page).to have_content('Determinate')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Ozullirn Abbella to Ross Jones')

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_unallocated_path
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Ross Jones (Probation POM)')
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature } do
    override_nomis_staff_id = 485_595

    signin_user

    visit new_allocations_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-2')
    check('override-3')
    click_button('Continue')

    expect(Override.count).to eq(1)

    expect(page).to have_current_path confirm_allocations_path(nomis_offender_id, override_nomis_staff_id)

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_unallocated_path
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Toby Retallick (Prison POM)')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: :override_allocation_feature } do
    signin_user

    visit new_allocations_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    click_button('Continue')
    expect(page).to have_content('Select one or more reasons for not accepting the recommendation')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing Other detail', vcr: { cassette_name: :override_allocation_feature } do
    signin_user

    visit new_allocations_path(nomis_offender_id)

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

    visit new_allocations_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-1')
    click_button('Continue')
    expect(page).to have_content('Enter reason for allocating this POM')
    expect(Override.count).to eq(0)
  end

  scenario 're-allocating', vcr: { cassette_name: :re_allocate_feature } do
    probation_officer_pom_detail.allocations.create!(
      nomis_offender_id: nomis_offender_id,
      nomis_staff_id: probation_officer_nomis_staff_id,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'A',
      created_by: 'spo@leeds.hmpps.gov.uk',
      active: true
    )

    signin_user

    visit summary_allocated_path

    within('.allocated_offender_row_0') do
      click_link 'Reallocate'
    end

    expect(page).to have_current_path edit_allocations_path(nomis_offender_id)
    expect(page).to have_css('.current_pom_full_name', text: 'Duckett, Jenny')
    expect(page).to have_css('.current_pom_grade', text: 'Prison POM')
  end

  scenario 'allocation fails', vcr: { cassette_name: :allocation_fails_feature } do
    allow(AllocationService).to receive(:create_allocation).and_return(false)
    signin_user

    visit new_allocations_path(nomis_offender_id)

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
end
