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

    visit new_prison_allocation_path('LEI', nomis_offender_id)

    expect(page).to have_content('Determinate')
    expect(page).to have_content('There is 1 POM unavailable for new allocations.')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Ozullirn Abbella to Ross Jones')

    click_button 'Complete allocation'

    expect(page).to have_current_path prison_summary_unallocated_path('LEI')
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Ross Jones (Probation POM)')
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature_ok } do
    override_nomis_staff_id = 485_737

    signin_user

    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    check('override-2')
    check('override-3')
    click_button('Continue')

    expect(Override.count).to eq(1)

    expect(page).to have_current_path prison_confirm_allocation_path('LEI', nomis_offender_id, override_nomis_staff_id)

    click_button 'Complete allocation'

    expect(page).to have_current_path prison_summary_unallocated_path('LEI')
    expect(page).to have_css('.notification', text: 'Ozullirn Abbella has been allocated to Jay Heal (Prison POM)')
    expect(Override.count).to eq(0)
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: :override_allocation_feature_validate_reasons } do
    signin_user

    visit new_prison_allocation_path('LEI', nomis_offender_id)

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

    visit new_prison_allocation_path('LEI', nomis_offender_id)

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

    visit new_prison_allocation_path('LEI', nomis_offender_id)

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
      primary_pom_nomis_id: probation_officer_nomis_staff_id,
      recommended_pom_type: 'probation'
    )

    signin_user

    visit prison_summary_allocated_path('LEI')

    within('.allocated_offender_row_0') do
      click_link 'View'
    end

    expect(page).to have_current_path prison_allocation_path('LEI', nomis_offender_id)
    expect(page).to have_link(nil, href: '/prisons/LEI/poms/485636')
    expect(page).to have_css('.table_cell__left_align', text: 'Duckett, Jenny')
    expect(page).to have_css('.table_cell__left_align', text: 'Supporting')

    click_link 'Reallocate'

    expect(page).to have_current_path edit_prison_allocation_path('LEI', nomis_offender_id)
    expect(page).to have_css('.current_pom_full_name', text: 'Duckett, Jenny')
    expect(page).to have_css('.current_pom_grade', text: 'Prison POM')

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_current_path prison_confirm_reallocation_path('LEI', nomis_offender_id, prison_officer_nomis_staff_id)

    click_button 'Complete allocation'

    expect(AllocationVersion.find_by(nomis_offender_id: nomis_offender_id).event).to eq("reallocate_primary_pom")
  end

  scenario 'allocation fails', vcr: { cassette_name: :allocation_fails_feature } do
    allow(AllocationService).to receive(:create_or_update).and_return(false)

    signin_user

    visit new_prison_allocation_path('LEI', nomis_offender_id)

    within('.recommended_pom_row_0') do
      click_link 'Allocate'
    end

    click_button 'Complete allocation'

    expect(page).to have_current_path prison_summary_unallocated_path('LEI')
    expect(page).to have_css(
      '.alert',
      text: 'Ozullirn Abbella has not been allocated - please try again'
    )
  end

  scenario 'cannot reallocate a non-allocated offender', vcr: { cassette_name: :allocation_attempt_bad_reallocate } do
    signin_user

    visit edit_prison_allocation_path('LEI', never_allocated_offender)
    expect(page).to have_current_path new_prison_allocation_path('LEI', never_allocated_offender)
  end

  scenario 'view allocation history for an offender', versioning: true, vcr: { cassette_name: :view_allocation_history } do
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: probation_officer_nomis_staff_id,
      recommended_pom_type: 'probation',
      created_at: Time.zone.now - 4.days,
      updated_at: Time.zone.now - 4.days,
      primary_pom_allocated_at: Time.zone.now - 4.days
    )

    reallocated_pom_name = "#{Faker::Name.first_name} #{Faker::Name.last_name}".titleize
    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

    allocation.update(event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                      primary_pom_nomis_id: prison_officer_nomis_staff_id,
                      primary_pom_name: reallocated_pom_name,
                      recommended_pom_type: 'prison',
                      updated_at: Time.zone.now - 3.days
    )

    allocation.update(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                      event_trigger: AllocationVersion::USER,
                      primary_pom_nomis_id: nil,
                      primary_pom_name: nil,
                      recommended_pom_type: nil,
                      updated_at: Time.zone.now - 2.days,
                      primary_pom_allocated_at: nil
    )

    deallocate_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y")

    new_prison_pom_name = "#{Faker::Name.first_name} #{Faker::Name.last_name}".titleize
    allocation.update(event: AllocationVersion::ALLOCATE_PRIMARY_POM,
                      prison: 'PVI',
                      primary_pom_nomis_id: 485_132,
                      primary_pom_name: new_prison_pom_name,
                      recommended_pom_type: 'prison',
                      updated_at: Time.zone.now - 1.day)

    allocation.update(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                      event_trigger: AllocationVersion::OFFENDER_TRANSFERRED,
                      primary_pom_nomis_id: nil,
                      primary_pom_name: nil,
                      recommended_pom_type: nil,
                      updated_at: Time.zone.now - 1.day,
                      primary_pom_allocated_at: nil)

    transfer_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y ")

    history = AllocationService.offender_allocation_history(nomis_offender_id)

    signin_user
    visit prison_allocation_history_path('LEI', nomis_offender_id)

    expect(page).to have_css('h1', text: "Abbella, Ozullirn")

    expect(page).to have_css('.govuk-heading-m', text: "HMP Pentonville")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner unallocated (transfer)")
    expect(page).to have_css('.time', text: transfer_date.to_s)

    pvi_allocation_date = history[1].updated_at.strftime("#{history[1].updated_at.day.ordinalize} %B %Y")

    expect(page).to have_css('p', text: "Prisoner allocated to #{history[1].primary_pom_name} Tier: #{history[1].allocated_at_tier}")
    expect(page).to have_css('.time', text: "#{pvi_allocation_date} by #{history[1].created_by_name.titleize}")

    expect(page).to have_css('.govuk-heading-m', text: "HMP Leeds")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner unallocated")
    expect(page).to have_css('.time', text: deallocate_date.to_s)

    previous_formatted_date = history[3].updated_at.strftime("#{history[3].updated_at.day.ordinalize} %B %Y")

    expect(page).to have_css('p', text: "Prisoner reallocated to #{history[3].primary_pom_name} Tier: #{history[3].allocated_at_tier}")
    expect(page).to have_css('.time', text: "#{previous_formatted_date} by #{history[3].created_by_name.titleize}")

    initial_allocated_date = history.last.updated_at.strftime("#{history.last.updated_at.day.ordinalize} %B %Y")
    expect(page).to have_css('p', text: "Prisoner allocated to #{history.last.primary_pom_name.titleize} Tier: #{history.last.allocated_at_tier}")
    expect(page).to have_css('.time', text: "#{initial_allocated_date} by #{history.last.created_by_name.titleize}")
  end
end
