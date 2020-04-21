require 'rails_helper'

feature 'Allocation' do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:prison_officer_nomis_staff_id) { 485_926 }
  let!(:nomis_offender_id) { 'G7266VD' }
  let(:offender_name) { 'Omistius Annole' }
  let!(:never_allocated_offender) { 'G1670VU' }

  let!(:probation_officer_pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }

  let!(:case_information) {
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS',
                              welsh_offender: 'No', probation_service: 'England')
  }

  before do
    signin_user
  end

  scenario 'accepting a recommended allocation', versioning: true, vcr: { cassette_name: :create_new_allocation_feature } do
    visit new_prison_allocation_path('LEI', nomis_offender_id)

    expect(page).to have_content('Determinate')

    within('#community_probation_service') do
      expect(page).to have_content('England')
      expect(page).to have_link('Change', href: edit_prison_case_information_path('LEI', nomis_offender_id))
    end

    expect(page).to have_content('There is 1 POM unavailable for new allocations.')

    within('.recommended_pom_row_0') do
      expect(page).to have_content 'Integration-Tests, Moic'
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: "You are allocating #{offender_name} to Moic Integration-Tests")

    click_button 'Complete allocation'

    expect(current_url).to have_content(prison_summary_unallocated_path('LEI'))
    expect(page).to have_css('.notification', text: "#{offender_name} has been allocated to Moic Integration-Tests (Probation POM)")
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature_ok } do
    # This is Amit's staff_id - he is top of the Prison POM list
    override_nomis_staff_id = 485_787

    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0', visible:  false) do
      click_link('Allocate', visible:  false)
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-2')
    check('override-3')
    click_button('Continue')

    expect(Override.count).to eq(1)

    expect(current_url).to have_content(prison_confirm_allocation_path('LEI', nomis_offender_id, override_nomis_staff_id))
    click_button 'Complete allocation'

    expect(current_url).to have_content(prison_summary_unallocated_path('LEI'))

    expect(page).to have_css('.notification', text: "#{offender_name} has been allocated to Amit Muthu (Prison POM)")
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: :override_allocation_feature_validate_reasons } do
    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0', visible:  false) do
      click_link('Allocate', visible:  false)
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    click_button('Continue')
    expect(page).to have_content('Select one or more reasons for not accepting the recommendation')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing Other detail', vcr: { cassette_name: :override_allocation_feature_validate_other } do
    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0', visible:  false) do
      click_link('Allocate', visible:  false)
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-4')
    click_button('Continue')
    expect(page).to have_content('Please provide extra detail when Other is selected')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing suitability detail', vcr: { cassette_name: :override_suitability_allocation_feature } do
    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0', visible:  false) do
      click_link('Allocate', visible:  false)
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-1')
    click_button('Continue')
    expect(page).to have_content('Enter reason for allocating this POM')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate the reason text area character limit', vcr: { cassette_name: :override_allocation__character_count_feature } do
    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0', visible:  false) do
      click_link('Allocate', visible:  false)
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-conditional-1')
    fill_in 'override[suitability_detail]', with: 'consectetur a eraconsectetur a erat nam at lectus urna duis convallis convallis tellus id interdum velit laoreet id donec ultrices tincidunt arcu non sodales neque sodales ut etiam'
    click_button('Continue')
    expect(page).to have_content('This reason cannot be more than 175 characters')
  end

  scenario 're-allocating', versioning: true, vcr: { cassette_name: :re_allocate_feature } do
    create(
      :allocation,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: 485_637,
      recommended_pom_type: 'probation'
    )

    visit prison_summary_allocated_path('LEI')

    within('.allocated_offender_row_0') do
      click_link 'View'
    end

    expect(current_url).to have_content(prison_allocation_path('LEI', nomis_offender_id))
    expect(page).to have_link(nil, href: "/prisons/LEI/poms/485637")
    expect(page).to have_css('.table_cell__left_align', text: 'Pobee-Norris, Kath')
    expect(page).to have_css('.table_cell__left_align', text: 'Responsible')

    click_link 'Reallocate'

    expect(current_url).to have_content(edit_prison_allocation_path('LEI', nomis_offender_id))
    expect(page).to have_css('.current_pom_full_name', text: 'Pobee-Norris, Kath')
    expect(page).to have_css('.current_pom_grade', text: 'Probation POM')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(current_url).to have_content(prison_confirm_reallocation_path('LEI', nomis_offender_id, 485_758))

    click_button 'Complete allocation'

    expect(Allocation.find_by(nomis_offender_id: nomis_offender_id).event).to eq("reallocate_primary_pom")
  end

  scenario 'allocation fails', vcr: { cassette_name: :allocation_fails_feature } do
    expect(AllocationService).to receive(:create_or_update).and_return(false)

    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    click_button 'Complete allocation'

    expect(current_url).to have_content(prison_summary_unallocated_path('LEI'))

    expect(page).to have_css(
      '.alert',
      text: "#{offender_name} has not been allocated - please try again"
    )
  end

  scenario 'cannot reallocate a non-allocated offender', vcr: { cassette_name: :allocation_attempt_bad_reallocate } do
    visit edit_prison_allocation_path('LEI', never_allocated_offender)
    expect(page).to have_current_path new_prison_allocation_path('LEI', never_allocated_offender)
  end
end
