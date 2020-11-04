# frozen_string_literal: true

require 'rails_helper'

feature 'delius import scenarios' do
  let(:ldu) {  create(:local_divisional_unit) }
  let(:team) { create(:team, local_divisional_unit: ldu) }
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }

  before do
    test_strategy.switch!(:auto_delius_import, true)
  end

  after do
    test_strategy.switch!(:auto_delius_import, false)
  end

  before do
    signin_spo_user
    stub_auth_token
    stub_user(staff_id: 123456)
  end

  context 'when one delius record' do
    let(:offender_no) { 'G4281GV' }
    let(:crn) { 'X45786587' }

    context 'with all data' do
      before do
        stub_community_offender(offender_no, build(:community_data, otherIds: { crn: crn }, offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
        stub_community_registrations(offender_no, [])

        stub_offender(build(:nomis_offender, offenderNo: offender_no))
      end

      before do
        ProcessDeliusDataJob.perform_now offender_no
      end

      it 'displays without error messages' do
        visit prison_case_information_path('LEI', offender_no)
        expect(page).not_to have_css('.govuk-error-summary')
        within '#offender_crn' do
          expect(page).to have_content crn
        end
      end
    end

    context 'without tier' do
      let(:offender_no) { 'G2911GD' }
      let(:offender) { build(:nomis_offender, offenderNo: offender_no) }

      before do
        stub_community_offender(offender_no, build(:community_data, currentTier: 'XX', offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
        stub_community_registrations(offender_no, [])

        stub_offender(offender)
        stub_offenders_for_prison('LEI', [offender])
      end

      before do
        ProcessDeliusDataJob.perform_now offender_no
      end

      it 'displays the correct error message' do
        visit prison_summary_pending_path('LEI')
        within "#edit_#{offender_no}" do
          click_link 'Update'
        end

        within '.govuk-error-summary' do
          expect(page).to have_content 'no tiering calculation found'
        end
      end
    end

    context 'with non-existant team' do
      let(:offender_no) { 'G2911GD' }
      let(:offender) { build(:nomis_offender, offenderNo: offender_no) }

      before do
        stub_community_offender(offender_no, build(:community_data))
        stub_community_registrations(offender_no, [])

        stub_offender(offender)
      end

      before do
        ProcessDeliusDataJob.perform_now offender_no
      end

      it 'displays the correct error message' do
        visit prison_case_information_path('LEI', offender_no)
        within '.govuk-error-summary' do
          expect(page).to have_content 'no community team information found'
        end
      end
    end
  end
end
