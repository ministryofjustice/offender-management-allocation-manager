require 'rails_helper'

feature 'Responsibility override' do
  include ActiveJob::TestHelper

  before do
    signin_user
  end

  let(:offender_id) { 'G8060UF' }
  let(:pom_id) { 485_926 }

  context 'when overriding responsibility', :queueing, vcr: { cassette_name: :override_responsibility } do
    before do
      ldu = create(:local_divisional_unit, email_address: 'ldu@test.com')
      create(:case_information, nomis_offender_id: offender_id, local_divisional_unit: ldu)
    end

    it 'overrides' do
      create(:allocation, primary_pom_nomis_id: pom_id, nomis_offender_id: offender_id)
      visit new_prison_allocation_path('LEI', offender_id)

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

      expect(page).to have_current_path(prison_allocation_path('LEI', offender_id))
    end
  end

  context "when override isn't possible due to lack of LDU address", vcr: { cassette_name: :cant_override_responsibility } do
    before do
      ldu = create(:local_divisional_unit, email_address: nil)
      create(:case_information, nomis_offender_id: offender_id, local_divisional_unit: ldu)
    end

    it 'doesnt override' do
      visit new_prison_allocation_path('LEI', offender_id)

      within '.responsibility_change' do
        click_link 'Change'
      end

      expect(page).to have_content "Responsibility for this case can't be changed"
    end
  end
end
