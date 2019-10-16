# frozen_string_literal: true

require 'rails_helper'

feature "early allocation questionaire", type: :feature, vcr: { cassette_name: :early_allocations } do
  let(:nomis_staff_id) { 485_637 }

  # This booking id is the latest one for the offender in T3
  let(:nomis_offender_id) { 'G4273GI' }
  let(:booking_id) { 1_153_753 }
  # any date less than 2 years in the past
  let(:valid_date) { Time.zone.today - 6.months }
  let(:prison) { 'LEI' }

  before do
    create(:case_information, nomis_offender_id: nomis_offender_id)
    create(:allocation_version, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id, nomis_booking_id: booking_id)

    signin_user

    visit prison_caseload_index_path(prison)

    # assert that our setup created a caseload record
    expect(page).to have_content("Showing 1 - 1 of 1 results")
  end

  context 'without early allocation enabled' do
    it 'shouldnt show the section' do
      click_link 'View'
      expect(page).not_to have_content 'Early allocation eligibility'
    end
  end

  context 'with Early allocation enabled' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      test_strategy.switch!(:early_allocation, true)
      click_link 'View'
      expect(page).to have_content 'Early allocation eligibility'
      click_link 'Assess Eligibility'
    end

    after do
      test_strategy.switch!(:early_allocation, false)
    end

    scenario 'error case followed by stage1 happy path' do
      click_button 'Continue'

      expect(page).to have_css('.govuk-error-message')
      expect(page).to have_css('#early_allocation_oasys_risk_assessment_date_error')
      expect(page).to have_css('#early_allocation_high_profile_error')
      within '.govuk-error-summary' do
        expect(page).to have_text 'You must say if this case is \'high profile\''
        click_link 'You must say if this case is \'high profile\''

        expect(all('li').count).to eq(6)
      end

      expect {
        stage1_eligible_answers

        click_button 'Continue'
        expect(page).not_to have_css('.govuk-error-message')
        # selecting any one of these as 'Yes' means that we progress to assessment complete (Yes)
        expect(page).to have_text('The community probation team will take responsibility')
      }.to change(EarlyAllocation, :count).by(1)
    end

    context 'when existing eligible early allocation' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: nomis_offender_id) }

      before do
        visit prison_prisoner_path(prison, nomis_offender_id)
      end

      it 'show re-assess' do
        within '#early_allocation' do
          expect(page).to have_text('Re-assess')
        end
      end
    end

    context 'with stage 2 questions' do
      before do
        fill_in id: 'early_allocation_oasys_risk_assessment_date_dd', with: valid_date.day
        fill_in id: 'early_allocation_oasys_risk_assessment_date_mm', with: valid_date.month
        fill_in id: 'early_allocation_oasys_risk_assessment_date_yyyy', with: valid_date.year

        find('#early_allocation_convicted_under_terrorisom_act_2000_false').click
        find('#early_allocation_high_profile_false').click
        find('#early_allocation_serious_crime_prevention_order_false').click
        find('#early_allocation_mappa_level_3_false').click
        find('#early_allocation_cppc_case_false').click

        click_button 'Continue'
        # make sure that we are displaying stage 2 questions before continuing
        expect(page).to have_text 'Has the prisoner been held in an extremism'
      end

      scenario 'error path' do
        click_button 'Continue'

        expect(page).to have_css('.govuk-error-message')
        expect(page).to have_css('.govuk-error-summary')

        within '.govuk-error-summary' do
          expect(page).to have_text 'You must say if this is a MAPPA 2 case'

          expect(all('li').count).to eq(5)
        end
      end

      scenario 'discretionary path' do
        find('#early_allocation_extremism_separation_false').click
        find('#early_allocation_high_risk_of_serious_harm_false').click
        find('#early_allocation_mappa_level_2_false').click
        find('#early_allocation_pathfinder_process_false').click
        find('#early_allocation_other_reason_true').click

        click_button 'Continue'
        expect(page).not_to have_text 'The community probation team will make a decision'

        # Last prompt before end of journey
        expect(page).to have_text 'Why are you referring this case for early allocation to the community?'
        click_button 'Continue'
        # we need to always tick the 'Head of Offender Management' box and fill in the reasons
        expect(page).to have_css('.govuk-error-message')

        fill_in id: 'early_allocation_reason', with: 'Just because'
        find('#early_allocation_approved').click
        click_button 'Continue'

        expect(page).to have_text 'The community probation team will make a decision'
      end

      scenario 'not eligible due to all answers false' do
        find('#early_allocation_extremism_separation_false').click
        find('#early_allocation_high_risk_of_serious_harm_false').click
        find('#early_allocation_mappa_level_2_false').click
        find('#early_allocation_pathfinder_process_false').click
        find('#early_allocation_other_reason_false').click

        click_button 'Continue'
        expect(page).to have_text 'Not eligible for early allocation'
      end
    end
  end

  def stage1_eligible_answers
    fill_in id: 'early_allocation_oasys_risk_assessment_date_dd', with: valid_date.day
    fill_in id: 'early_allocation_oasys_risk_assessment_date_mm', with: valid_date.month
    fill_in id: 'early_allocation_oasys_risk_assessment_date_yyyy', with: valid_date.year

    find('#early_allocation_convicted_under_terrorisom_act_2000_true').click
    find('#early_allocation_high_profile_false').click
    find('#early_allocation_serious_crime_prevention_order_false').click
    find('#early_allocation_mappa_level_3_false').click
    find('#early_allocation_cppc_case_false').click
  end
end
