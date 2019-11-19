require 'rails_helper'

# All these tests can use the same VCR cassette as they all visit the same path
feature 'delius import scenarios', vcr: { cassette_name: :delius_import_scenarios } do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:auto_delius_import, true)
  end

  before do
    signin_user
  end

  context 'when one delius record' do
    context 'when updating the COM name', :versioning do
      let!(:d1) { create(:delius_data, offender_manager: 'Mr Todd') }
      let(:create_time) { 3.days.ago }
      let(:update_time) { 2.days.ago }
      let(:subject) { AllocationService.offender_allocation_history(d1.noms_no) }

      before do
        x = create(:allocation_version, allocated_at_tier: 'C', nomis_offender_id: d1.noms_no, created_at: create_time, updated_at: create_time)
        x.update(allocated_at_tier: 'D', updated_at: update_time)
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'doesnt mess up the allocation history' do
        expect(subject.size).to eq(2)
        expect(subject.map(&:updated_at)).to eq([update_time, create_time])
      end
    end

    context 'with all data' do
      let!(:d1) { create(:delius_data) }

      before do
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'displays without error messages' do
        visit prison_case_information_path('LEI', d1.noms_no)
        expect(page).not_to have_css('.govuk-error-summary')
        within '#offender_crn' do
          expect(page).to have_content d1.crn
        end
      end
    end

    context 'without tier' do
      # This NOMIS id needs to appear on the first page of 'missing information'
      let(:d1) { create(:delius_data, noms_no: 'G2911GD', date_of_birth: '05/06/1974', tier: 'XX') }

      before do
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'displays the correct error message' do
        visit prison_summary_pending_path('LEI')
        within "#edit_#{d1.noms_no}" do
          click_link 'Update'
        end

        within '.govuk-error-summary' do
          expect(page).to have_content 'no tiering calculation found'
        end
      end
    end

    context 'without provider code' do
      let(:d1) { create(:delius_data, provider_code: nil) }

      before do
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'displays the correct error message' do
        visit prison_case_information_path('LEI', d1.noms_no)
        within '.govuk-error-summary' do
          expect(page).to have_content 'prisoner number but no service provider information'
        end
      end
    end

    context 'without LDU' do
      let(:d1) { create(:delius_data, ldu: nil, ldu_code: nil) }

      before do
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'displays the correct error message' do
        visit prison_case_information_path('LEI', d1.noms_no)
        within '.govuk-error-summary' do
          expect(page).to have_content 'no local divisional unit (LDU) information found'
        end
      end
    end

    context 'without team' do
      let(:d1) { create(:delius_data, team: nil) }

      before do
        ProcessDeliusDataJob.perform_now d1.noms_no
      end

      it 'displays the correct error message' do
        visit prison_case_information_path('LEI', d1.noms_no)
        within '.govuk-error-summary' do
          expect(page).to have_content 'no community team information found'
        end
      end
    end
  end

  context 'when there is no nDelius record' do
    it 'shows a message that there is no nDelius record' do
      visit prison_case_information_path('LEI', 'G7998GJ')
      within '.govuk-error-summary' do
        expect(page).to have_content 'No nDelius record found with this prisoner number'
      end
    end
  end

  context 'when a duplicate noms_no detected' do
    let!(:d1) { create(:delius_data) }
    let!(:d2) { create(:delius_data, noms_no: d1.noms_no) }

    before do
      ProcessDeliusDataJob.perform_now d1.noms_no
    end

    it 'displays a duplicate error message, and the 2 affected CRNs' do
      visit prison_case_information_path('LEI', d1.noms_no)
      within '.govuk-error-summary' do
        expect(page).to have_content 'More than one nDelius record found with this prisoner number'
      end
      within '#offender_crn' do
        expect(page).to have_content "#{d1.crn}#{d2.crn}"
      end
    end
  end
end
