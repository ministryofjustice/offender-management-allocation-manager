require 'rails_helper'

feature 'Allocation' do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:prison_officer_nomis_staff_id) { 485_926 }
  let!(:nomis_offender_id) { 'G7266VD' }
  let(:offender_name) { 'Omistius Annole' }
  let!(:never_allocated_offender) { 'G9403UP' }
  let!(:unallocated_offender_name) { 'Albina, Obinins' }

  let!(:probation_officer_pom_detail) {
    PomDetail.create!(
      prison_code: 'LEI',
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }

  let!(:case_information) {
    create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id), tier: 'A', case_allocation: 'NPS', probation_service: 'England')
    create(:case_information, offender: build(:offender, nomis_offender_id: never_allocated_offender))
  }

  before do
    signin_spo_user
  end

  scenario 'accepting a recommended allocation', vcr: { cassette_name: 'prison_api/create_new_allocation_feature' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    expect(page).to have_content('Determinate')

    within '#recommended_poms' do
      # 6th POM in the list is Moic Integration-Tests
      within 'tbody > tr:nth-child(6)' do
        expect(all('td[aria-label="POM name"]').map(&:text).first).to eq('Moic Integration-Tests')
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: "You are allocating #{offender_name} to Moic Integration-Tests")

    click_button 'Complete allocation'

    expect(current_url).to have_content(unallocated_prison_prisoners_path('LEI'))
    expect(page).to have_css('.notification', text: "#{offender_name} has been allocated to Moic Integration-Tests (Probation POM)")
  end

  scenario 'overriding an allocation', vcr: { cassette_name: 'prison_api/override_allocation_feature_ok' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)
    find('#non-recommended-accordion-section-heading').click

    # Amit is 6th on the non-recommended list
    within '#non-recommended-accordion-section' do
      within 'tbody > tr:nth-child(6)' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    find('label[for=override-form-override-reasons-no-staff-field]').click
    find('label[for=override-form-override-reasons-continuity-field]').click

    click_button('Continue')

    click_button 'Complete allocation'
    expect(current_url).to have_content(unallocated_prison_prisoners_path('LEI'))
    expect(page).to have_css('.notification', text: "#{offender_name} has been allocated to Amit Muthu (Prison POM)")
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: 'prison_api/override_allocation_feature_validate_reasons' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    find('#non-recommended-accordion-section-heading').click

    within '#non-recommended-accordion-section' do
      within 'tbody > tr:nth-child(1)' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    click_button('Continue')
    expect(page).to have_content('Select one or more reasons for not accepting the recommendation')
  end

  scenario 'overriding an allocation can validate missing Other detail', vcr: { cassette_name: 'prison_api/override_allocation_feature_validate_other' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    find('#non-recommended-accordion-section-heading').click

    # Amit is 6th on the non-recommended list
    within '#non-recommended-accordion-section' do
      within 'tbody > tr:nth-child(1)' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    find('label[for=override-form-override-reasons-other-field]').click
    click_button('Continue')

    expect(page).to have_content('Please provide extra detail when Other is selected')
  end

  scenario 'overriding an allocation can validate missing suitability detail', vcr: { cassette_name: 'prison_api/override_suitability_allocation_feature' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    find('#non-recommended-accordion-section-heading').click

    within '#non-recommended-accordion-section' do
      within 'tbody > tr:nth-child(1)' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    find('label[for=override-form-override-reasons-suitability-field]').click
    click_button('Continue')
    expect(page).to have_content('Enter reason for allocating this POM')
  end

  scenario 'overriding an allocation can validate the reason text area character limit', vcr: { cassette_name: 'prison_api/override_allocation__character_count_feature' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    find('#non-recommended-accordion-section-heading').click

    within '#non-recommended-accordion-section' do
      within 'tbody > tr:nth-child(1)' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison officer POM?')

    find('label[for=override-form-override-reasons-suitability-field]').click
    fill_in 'override-form-suitability-detail-field', with: 'consectetur a eraconsectetur a erat nam at lectus urna duis convallis convallis tellus id interdum velit laoreet id donec ultrices tincidunt arcu non sodales neque sodales ut etiam'
    click_button('Continue')
    expect(page).to have_content('This reason cannot be more than 175 characters')
  end

  scenario 're-allocating', vcr: { cassette_name: 'prison_api/re_allocate_feature' } do
    create(
      :allocation_history,
      prison: 'LEI',
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: 485_735,
      recommended_pom_type: 'probation'
    )

    visit allocated_prison_prisoners_path('LEI')
    within('.allocated_offender_row_0') do
      click_link 'View'
    end
    expect(current_url).to have_content(prison_prisoner_allocation_path('LEI', nomis_offender_id))
    expect(page).to have_link(nil, href: "/prisons/LEI/poms/485735")
    expect(page).to have_css('.table_cell__left_align', text: 'Jara Duncan, Laura')
    expect(page).to have_css('.table_cell__left_align', text: 'Responsible')

    click_link 'Reallocate'

    expect(page).to have_css('.current_pom_full_name', text: 'Jara Duncan, Laura')
    expect(page).to have_css('.current_pom_grade', text: 'Probation POM')

    within '#recommended_poms' do
      within 'tbody > tr:nth-child(1)' do
        click_link 'Allocate'
      end
    end

    click_button 'Complete allocation'

    expect(AllocationHistory.find_by(nomis_offender_id: nomis_offender_id).event).to eq("reallocate_primary_pom")
  end

  context 'with a community override' do
    before do
      create(:responsibility, nomis_offender_id: never_allocated_offender)
    end

    scenario 'removing a community override', vcr: { cassette_name: 'prison_api/allocation_remove_community_override' } do
      visit prison_dashboard_index_path('LEI')
      click_link 'Make new allocations'
      find '.offender_row_0'
      within '.offender_row_0' do
        click_link unallocated_offender_name
      end

      find '.responsibility_change'
      within '.responsibility_change' do
        click_link 'Change'
      end
      click_button 'Confirm'
      expect(all('.govuk-error-summary').count).to eq(1)

      fill_in('responsibility[reason_text]', with: Faker::Lorem.sentence)
      click_button 'Confirm'

      expect(page).to have_current_path(prison_prisoner_staff_index_path('LEI', never_allocated_offender), ignore_query: true)
    end
  end
end
