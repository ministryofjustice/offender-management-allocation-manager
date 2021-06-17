require 'rails_helper'

feature 'Responsibility override' do
  include ActiveJob::TestHelper

  before do
    signin_spo_user
  end

  let(:offender_id) { 'G8060UF' }
  let(:pom_id) { 485_926 }

  context 'when overriding responsibility', vcr: { cassette_name: 'prison_api/override_responsibility' } do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_id))
    end

    context 'with an allocation' do
      before do
        create(:allocation_history, prison: 'LEI', primary_pom_nomis_id: pom_id, nomis_offender_id: offender_id)
      end

      it 'overrides' do
        visit prison_prisoner_allocation_path('LEI', offender_id)

        within '.responsibility_change' do
          click_link 'Change'
        end

        expect(page).not_to have_css('govuk-textarea--error')
        click_button 'Continue'

        expect(page).to have_content 'Select a reason for overriding the responsibility'
        find('#reason_recall').click
        click_button 'Continue'

        expect {
          click_button 'Confirm'
        }.to change(enqueued_jobs, :count).by(2)

        expect(page).to have_content 'Current responsibility Community'
        expect(page).to have_current_path(prison_prisoner_allocation_path('LEI', offender_id))
      end
    end

    context 'without allocation' do
      it 'overrides' do
        visit prison_prisoner_staff_index_path('LEI', offender_id)

        within '.responsibility_change' do
          click_link 'Change'
        end

        find('#reason_prob_team').click
        click_button 'Continue'

        expect {
          click_button 'Confirm'
        }.to change(enqueued_jobs, :count).by(2)

        expect(page).to have_current_path(prison_prisoner_staff_index_path('LEI', offender_id))
        expect(page).to have_content 'Current case owner Community'
      end

      it 'shows the correct POM recommendations' do
        override_responsibility_for(offender_id)

        visit prison_prisoner_staff_index_path('LEI', offender_id)
        expect(page).to have_content 'Recommendation: Prison officer POM'
      end

      it 'shows case owner as Community when overridden' do
        override_responsibility_for(offender_id)

        visit unallocated_prison_prisoners_path('LEI')

        within 'tr.govuk-table__row.offender_row_0' do
          expect(page).to have_content('Community')
        end
      end
    end
  end

  context "when override isn't possible due to email address is nil", vcr: { cassette_name: 'prison_api/cant_override_responsibility_nil_email' } do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_id), local_delivery_unit: nil)
    end

    it 'doesnt override' do
      visit prison_prisoner_staff_index_path('LEI', offender_id)

      within '.responsibility_change' do
        click_link 'Change'
      end

      expect(page).to have_content "Responsibility for this case can't be changed"
    end
  end

  def override_responsibility_for(offender_id)
    visit prison_prisoner_staff_index_path('LEI', offender_id)

    within '.responsibility_change' do
      click_link 'Change'
    end

    find('#reason_prob_team').click
    click_button 'Continue'
    click_button 'Confirm'
  end
end
