require 'rails_helper'

feature 'Responsibility override' do
  include ActiveJob::TestHelper

  before do
    signin_user
  end

  context 'when overriding responsibility', :queueing, vcr: { cassette_name: :override_responsibility } do
    let(:offender_id) { 'G8060UF' }

    before do
      ldu = create(:local_divisional_unit, email_address: 'ldu@test.com')
      create(:case_information, nomis_offender_id: offender_id, local_divisional_unit: ldu)
    end

    it 'overrides' do
      visit new_prison_allocation_path('LEI', offender_id)

      within '.responsibility_change' do
        click_link 'Change'
      end

      click_button 'Continue'

      expect(page).to have_content 'Select a reason for overriding the responsibility'

      find('#reason_recall').click
      click_button 'Continue'

      expect {
        click_button 'Confirm'
      }.to change(enqueued_jobs, :count).by(1)

      expect(page).to have_content 'Current case owner Community'
    end
  end
end
