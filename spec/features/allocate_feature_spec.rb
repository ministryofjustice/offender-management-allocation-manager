require 'rails_helper'

feature 'Allocation' do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:prison_officer_nomis_staff_id) { 485_926 }
  let!(:nomis_offender_id) { 'G7266VD' }
  let(:offender_name) { 'Omistius Annole' }
  let!(:never_allocated_offender_id) { 'G9403UP' }
  let!(:unallocated_offender_name) { 'Albina, Obinins' }
  let(:recently_allocated_offender_name) { 'Obinins Albina' }

  let!(:probation_officer_pom_detail) do
    PomDetail.create(
      prison_code: 'LEI',
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  end

  let!(:case_information) do
    create(:case_information, :english, offender: build(:offender, nomis_offender_id: nomis_offender_id), tier: 'A', enhanced_resourcing: true)
    create(:case_information, offender: build(:offender, nomis_offender_id: never_allocated_offender_id))
  end

  let(:blank_mappa) do
    { category: nil, level: nil, short_description: nil, review_date: nil, start_date: nil }
  end

  before do
    allow(HmppsApi::PrisonTimelineApi).to receive(:get_prison_timeline).and_return(
      { "prisonPeriod" => [{ 'prisons' => ['ABC', 'DEF'] }] }
    )

    allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).and_return(nil)
    allow(OffenderService).to receive(:get_mappa_details).and_return(blank_mappa)
    allow_any_instance_of(StaffMember).to receive(:email_address).and_return('pom@example.com')
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return({ status: :missing })

    signin_spo_user
  end

  context 'when a journey begins on the "Make allocations" page' do
    let(:start_page) { unallocated_prison_prisoners_path('LEI') }

    before do
      visit start_page
      click_link unallocated_offender_name

      # Takes you to the Review case page
      expect(page).to have_css('h1', text: "Review Obinins Albina's case")
      expect(page).to have_content('Determinate')

      within '.moj-page-header-actions__actions' do
        click_link 'Choose POM'
      end

      # Takes you to the Choose a POM page
      expect(page).to have_css('h1', text: "Allocate a POM to Obinins Albina")
    end

    scenario 'accepting the recommended POM type', vcr: { cassette_name: 'prison_api/create_new_allocation_feature' } do
      # Allocate to the Prison POM called "Moic Pom"
      within row_containing 'Moic Pom' do
        click_link 'Allocate'
      end

      expect(page).to have_css('h1', text: "Check allocation details for #{recently_allocated_offender_name}")

      click_button 'Complete allocation'

      expect(page).to have_current_path(start_page)
      expect(page).to have_css('.message', text: "#{recently_allocated_offender_name} allocated to Moic Pom")
      expect(page).to have_css('.govuk-details__summary-text', text: "You can copy information about this allocation to paste into an email to someone else")
    end

    scenario 'using the compare POMs page', vcr: { cassette_name: 'prison_api/use_compare_feature' } do
      within row_containing 'Moic Pom' do
        find('input[type=checkbox]').click
      end

      click_button 'Compare workloads'
      expect(page).to have_content('Compare POMs for')

      # Follow link in box
      click_link '0 allocations in last 7 days'
      expect(page).to have_content('No cases allocated in last 7 days')
      click_link 'Back'

      find('a.govuk-button').click # 'Allocate' button - cucumber seems to think it's "disabled", bless it
      expect(page).to have_css('h1', text: "Check allocation details for #{recently_allocated_offender_name}")

      click_button 'Complete allocation'

      expect(page).to have_current_path(start_page)
      expect(page).to have_css('.message', text: "#{recently_allocated_offender_name} allocated to Moic Pom")
      expect(page).to have_css('.govuk-details__summary-text', text: "You can copy information about this allocation to paste into an email to someone else")
    end

    scenario 'using the compare POM page with no POMs checked', vcr: { cassette_name: 'prison_api/use_compare_with_none_checked_feature' }, flaky: true do
      click_button 'Compare workloads'
      expect(page).to have_css('div#pom-selection-error')
    end

    scenario 'overriding the recommended POM type', vcr: { cassette_name: 'prison_api/override_allocation_feature_ok' } do
      # Allocate to the Probation POM called "Moic Integration-Tests"
      within row_containing 'Moic Integration-Tests' do
        click_link 'Allocate'
      end

      expect(page).to have_css('h1', text: 'Why are you allocating a probation POM?')

      find('label[for=override-form-override-reasons-no-staff-field]').click
      find('label[for=override-form-override-reasons-continuity-field]').click

      click_button('Continue')

      click_button 'Complete allocation'
      # Returns to the "Make new allocation" page

      expect(current_url).to have_content(unallocated_prison_prisoners_path('LEI'))
      expect(page).to have_css('.message', text: "#{recently_allocated_offender_name} allocated to Moic Integration-Tests")
      expect(page).to have_css('.govuk-details__summary-text', text: "You can copy information about this allocation to paste into an email to someone else")
    end
  end

  scenario 'overriding an allocation can validate missing reasons', vcr: { cassette_name: 'prison_api/override_allocation_feature_validate_reasons' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    # Select a prison POM (recommended is Probation)
    within row_containing 'Moic Pom' do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison POM?')

    click_button('Continue')
    expect(page).to have_content('Select one or more reasons for not accepting the recommendation')
  end

  scenario 'overriding an allocation can validate missing Other detail', vcr: { cassette_name: 'prison_api/override_allocation_feature_validate_other' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    # Select a prison POM (recommended is Probation)
    within row_containing 'Moic Pom' do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison POM?')

    find('label[for=override-form-override-reasons-other-field]').click
    click_button('Continue')

    expect(page).to have_content('Please provide extra detail when Other is selected')
  end

  scenario 'overriding an allocation can validate missing suitability detail', vcr: { cassette_name: 'prison_api/override_suitability_allocation_feature' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    # Select a prison POM (recommended is Probation)
    within row_containing 'Moic Pom' do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison POM?')

    find('label[for=override-form-override-reasons-suitability-field]').click
    click_button('Continue')
    expect(page).to have_content('Enter reason for allocating this POM')
  end

  scenario 'overriding an allocation can validate the reason text area character limit', vcr: { cassette_name: 'prison_api/override_allocation__character_count_feature' } do
    visit prison_prisoner_staff_index_path('LEI', nomis_offender_id)

    # Select a prison POM (recommended is Probation)
    within row_containing 'Moic Pom' do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Why are you allocating a prison POM?')

    find('label[for=override-form-override-reasons-suitability-field]').click
    fill_in 'override-form-suitability-detail-field', with: 'consectetur a eraconsectetur a erat nam at lectus urna duis convallis convallis tellus id interdum velit laoreet id donec ultrices tincidunt arcu non sodales neque sodales ut etiam'
    click_button('Continue')
    expect(page).to have_content('This reason cannot be more than 175 characters')
  end

  scenario 're-allocating', vcr: { cassette_name: 'prison_api/re_allocate_feature' }, local_only: true do
    create(
      :allocation_history,
      prison: 'LEI',
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: 485_735,
      recommended_pom_type: 'probation'
    )

    # Go to 'Allocations' page
    visit allocated_prison_prisoners_path('LEI')
    expect(page).to have_text('See allocations')
    all('.allocated_offender_row_0 a').first.click # Click the one and only offender

    # Now on the 'Allocation information' page
    click_link 'Reallocate'

    # Now on the 'Review case' page
    expect(page).to have_text("Currently allocated to Laura Jara Duncan")
    expect(page).to have_css('.govuk-table__cell', text: 'Laura Jara Duncan')

    click_link 'Choose a POM to allocate to now'

    # Now on the 'Choose a POM' page
    expect(page).to have_text('Reallocate a POM to')
    expect(page).to have_text("Currently allocated to Laura Jara Duncan")
    expect(page).to have_current_path(prison_prisoner_staff_index_path(prison_id: 'LEI', prisoner_id: nomis_offender_id))

    within 'table#available-poms > tbody > tr:first' do
      click_link 'Allocate'
    end

    # Takes you to the 'Check allocation' page
    expect(page).to have_text('Check allocation details')
    expect(page).to have_text('We will send the information below to')
    expect(page).to have_text('Allocating from:')
    expect(page).to have_text('Allocating to:')

    click_button 'Complete allocation'

    # Returns to the 'See allocations' page with a success message
    expect(page).to have_text('See allocations')
    expect(page).to have_text('Allocating from:')
    expect(page).to have_text('Allocating to:')
    expect(AllocationHistory.find_by(nomis_offender_id: nomis_offender_id).event).to eq("reallocate_primary_pom")
  end

  context 'with a community override' do
    before do
      create(
        :allocation_history,
        prison: 'LEI',
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: 485_735,
        recommended_pom_type: 'probation'
      )

      create(:responsibility, nomis_offender_id: nomis_offender_id, value: 'Prison')
    end

    scenario 'removing a community override', vcr: { cassette_name: 'prison_api/allocation_remove_community_override' }, local_only: true do
      visit prison_dashboard_index_path('LEI')
      click_link 'All allocated cases'

      #  Now on the allocated offenders page
      all('.allocated_offender_row_0 a').first.click # Click the one and only offender

      # Now on the 'Allocation information' page
      within '.responsibility_change' do
        click_link 'Change'
      end

      expect(page).to have_text('Why are you changing responsibility for this case?')

      # Proceed without any input
      click_button 'Continue'
      expect(all('.govuk-error-summary').count).to eq(1)

      # Supply input
      find('label[for=responsibility-reason-other-reason-field]').click
      fill_in('responsibility[reason_text]', with: Faker::Lorem.sentence)
      click_button 'Continue'

      expect(page).to have_text('Confirm change of responsibility for this case')
      click_button 'Confirm'

      expect(page).to have_current_path(prison_prisoner_allocation_path('LEI', nomis_offender_id))
    end
  end
end
