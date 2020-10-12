# frozen_string_literal: true

require 'rails_helper'

feature "early allocation", type: :feature, vcr: { cassette_name: :early_allocations } do
  let(:nomis_staff_id) { 485_926 }
  # This booking id is the latest one for the offender in T3
  let(:nomis_offender_id) { 'G4273GI' }
  let(:booking_id) { 1_153_753 }
  # any date less than 3 months
  let(:valid_date) { Time.zone.today - 2.months }
  let(:prison) { 'LEI' }

  before do
    create(:case_information, nomis_offender_id: nomis_offender_id)
    create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id, nomis_booking_id: booking_id)

    signin_pom_user
    signin_spo_user

    visit prison_staff_caseload_index_path(prison, nomis_staff_id)

    # assert that our setup created a caseload record
    expect(page).to have_content("Showing 1 - 1 of 1 results")
  end

  context 'without switch' do
    it 'does not show the section' do
      click_link 'Abbella, Ozullirn'
      expect(page).not_to have_content 'Early allocation eligibility'
    end
  end

  context 'with switch' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      test_strategy.switch!(:early_allocation, true)
    end

    after do
      test_strategy.switch!(:early_allocation, false)
    end

    context 'without existing early allocation' do
      before do
        click_link 'Abbella, Ozullirn'
        expect(page).to have_content 'Early allocation eligibility'
        click_link 'Assess eligibility'
      end

      context 'when an immediate error occurs' do
        before do
          click_button 'Continue'
        end

        scenario 'error case' do
          expect(page).to have_css('.govuk-error-message')
          expect(page).to have_css('#early_allocation_oasys_risk_assessment_date_error')
          expect(page).to have_css('#early-allocation-high-profile-error')
          within '.govuk-error-summary' do
            expect(page).to have_text 'You must say if this case is \'high profile\''
            click_link 'You must say if this case is \'high profile\''
            expect(all('li').count).to eq(6)
          end
        end
      end

      scenario 'stage1 happy path' do
        expect {
          stage1_eligible_answers

          click_button 'Continue'
          expect(page).not_to have_css('.govuk-error-message')
          # selecting any one of these as 'Yes' means that we progress to assessment complete (Yes)
          expect(page).to have_text('The community probation team will take responsibility')
        }.to change(EarlyAllocation, :count).by(1)
        click_link 'Return to prisoner page'
        expect(page).to have_text 'Eligible'
      end

      scenario 'displaying the PDF' do
        stage1_eligible_answers

        click_button 'Continue'
        expect(page).not_to have_css('.govuk-error-message')
        # selecting any one of these as 'Yes' means that we progress to assessment complete (Yes)
        expect(page).to have_text('The community probation team will take responsibility')
        click_link 'Save completed assessment (pdf)'
        expect(page).to have_current_path('/prisons/LEI/prisoners/G4273GI/early_allocation.pdf')
      end

      context 'with stage 2 questions' do
        before do
          stage1_stage2_answers

          click_button 'Continue'
          # make sure that we are displaying stage 2 questions before continuing
          expect(page).to have_text 'Has the prisoner been held in an extremism'
        end

        scenario 'error path' do
          click_button 'Continue'

          expect(page).to have_css('.govuk-error-message')
          expect(page).to have_css('.govuk-error-summary')

          within '.govuk-error-summary' do
            expect(page).to have_text 'You must say if this is a MAPPA level 2 case'

            expect(all('li').count).to eq(5)
          end
        end

        context 'with discretionary path' do
          before do
            find('#early_allocation_extremism_separation_false').click
            find('#early-allocation-high-risk-of-serious-harm-field').click
            find('#early-allocation-mappa-level-2-field').click
            find('#early-allocation-pathfinder-process-field').click
            find('#early-allocation-other-reason-true-field').click

            click_button 'Continue'
            expect(page).not_to have_text 'The community probation team will make a decision'

            # Last prompt before end of journey
            expect(page).to have_text 'Why are you referring this case for early allocation to the community?'
            click_button 'Continue'
            # we need to always tick the 'Head of Offender Management' box and fill in the reasons
            expect(page).to have_css('.govuk-error-message')

            expect {
              fill_in id: 'early_allocation_reason', with: 'Just because'
              find('#early_allocation_approved').click
              click_button 'Continue'
            }.to change(EarlyAllocation, :count).by(1)

            expect(page).to have_text 'The community probation team will make a decision'
          end

          scenario 'saving the PDF' do
            click_link 'Save completed assessment (pdf)'
            expect(page).to have_current_path('/prisons/LEI/prisoners/G4273GI/early_allocation.pdf')
          end

          scenario 'completing the journey' do
            click_link 'Return to prisoner page'
            expect(page).to have_content 'Waiting for community decision'
            within '#early_allocation' do
              click_link 'Update'
            end

            click_button('Save')
            expect(page).to have_css('.govuk-error-message')
            within '.govuk-error-summary' do
              expect(all('li').count).to eq(1)
            end
            expect(page).to have_text 'You must say whether the community has accepted this case or not'

            find('#early_allocation_community_decision_true').click
            click_button('Save')
            expect(page).to have_text('Re-assess')
            expect(page).to have_text 'Eligible'
          end
        end

        scenario 'not eligible due to all answers false' do
          find('#early_allocation_extremism_separation_false').click
          find('#early-allocation-high-risk-of-serious-harm-field').click
          find('#early-allocation-mappa-level-2-field').click
          find('#early-allocation-pathfinder-process-field').click
          find('#early-allocation-other-reason-field').click

          click_button 'Continue'
          expect(page).to have_text 'Not eligible for early allocation'
          click_link 'Save completed assessment (pdf)'
          expect(page).to have_current_path('/prisons/LEI/prisoners/G4273GI/early_allocation.pdf')
        end
      end
    end

    context 'when existing eligible early allocation' do
      before do
        create(:early_allocation, :discretionary,
               nomis_offender_id: nomis_offender_id,
               community_decision: true)
        click_link 'Abbella, Ozullirn'
      end

      it 'has a re-assess link' do
        expect(page).to have_link 'Re-assess'
      end

      context 'when reassessing' do
        before do
          within '#early_allocation' do
            click_link 'Re-assess'
          end
        end

        it 'creates a new assessment' do
          expect {
            stage1_eligible_answers
            click_button 'Continue'
          }.to change(EarlyAllocation, :count).by(1)
        end

        it 'can do stage2' do
          stage1_stage2_answers
          click_button 'Continue'
          expect(page).not_to have_css('.govuk-error-message')
        end
      end
    end
  end

  def stage1_eligible_answers
    fill_in id: 'early_allocation_oasys_risk_assessment_date_dd', with: valid_date.day
    fill_in id: 'early_allocation_oasys_risk_assessment_date_mm', with: valid_date.month
    fill_in id: 'early_allocation_oasys_risk_assessment_date_yyyy', with: valid_date.year

    find('#early-allocation-convicted-under-terrorisom-act-2000-true-field').click
    find('#early-allocation-high-profile-field').click
    find('#early-allocation-serious-crime-prevention-order-field').click
    find('#early-allocation-mappa-level-3-field').click
    find('#early-allocation-cppc-case-field').click
  end

  def stage1_stage2_answers
    fill_in id: 'early_allocation_oasys_risk_assessment_date_dd', with: valid_date.day
    fill_in id: 'early_allocation_oasys_risk_assessment_date_mm', with: valid_date.month
    fill_in id: 'early_allocation_oasys_risk_assessment_date_yyyy', with: valid_date.year

    find('#early-allocation-convicted-under-terrorisom-act-2000-field').click
    find('#early-allocation-high-profile-field').click
    find('#early-allocation-serious-crime-prevention-order-field').click
    find('#early-allocation-mappa-level-3-field').click
    find('#early-allocation-cppc-case-field').click
  end
end
