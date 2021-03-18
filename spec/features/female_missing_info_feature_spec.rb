# frozen_string_literal: true

require "rails_helper"

feature "womens missing info journey" do
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:prison) { build(:womens_prison) }
  let(:offender) { build(:nomis_offender) }
  let(:prisoner_id) { offender.fetch(:offenderNo) }
  let(:user) { build(:pom) }

  before do
    stub_signin_spo user, [prison.code]
    stub_poms(prison.code, [user])
    stub_offenders_for_prison(prison.code, [offender])
    test_strategy.switch!(:womens_estate, true)
  end

  after do
    test_strategy.switch!(:womens_estate, false)
  end

  context 'without any data' do
    before do
      allow(ComplexityMicroService).to receive(:get_complexity).with(prisoner_id).and_return(nil)
      expect(ComplexityMicroService).to receive(:save).with(prisoner_id, level: 'low', username: 'MOIC_POM', reason: nil)
    end

    it 'has a happy path' do
      visit missing_information_prison_prisoners_path prison.code
      click_link 'Add missing details'

      # bang the update button - expect a big red error message
      click_button 'Update'
      within '.govuk-error-summary' do
        expect(all('li').map(&:text)).
          to match_array(["You must choose a complexity level"])
      end

      find('label[for=complexity-form-complexity-level-low-field]').click
      click_button 'Update'
      expect {
        #  again should have lots of error messages
        click_button 'Update'
        within '.govuk-error-summary' do
          expect(all('li').map(&:text)).
            to match_array(
              [
                "Select yes if the prisoner’s last known address was in Wales",
                "Select the prisoner’s tier",
                "Select the service provider for this case",
                # Yes this is a defect - we validate both Probation Service and Welshness
                "is not included in the list"
              ])
        end

        find('label[for=case-information-welsh-offender-no-field]').click
        click_button 'Update'
        # defect goes away once we fill in welshness correctly
        within '.govuk-error-summary' do
          expect(all('li').map(&:text)).
            to match_array(
              [
                "Select the prisoner’s tier",
                "Select the service provider for this case",
              ])
        end

        # There are some subtleties here - the first field has been renamed (e.g) case-information-welsh-offender-field-error
        # so pick the second one to avoid the noise
        find('label[for=case-information-case-allocation-crc-field]').click
        find('label[for=case-information-tier-b-field]').click
        click_button 'Update'
        wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
      }.to change(CaseInformation, :count).by(1)
    end
  end

  context 'when case information is present' do
    before do
      allow(ComplexityMicroService).to receive(:get_complexity).with(prisoner_id).and_return(nil)
      create(:case_information, nomis_offender_id: prisoner_id)
      expect(ComplexityMicroService).to receive(:save).with(prisoner_id, level: 'medium', username: 'MOIC_POM', reason: nil)

      visit missing_information_prison_prisoners_path prison.code
      click_link 'Add missing details'

      find('label[for=complexity-form-complexity-level-medium-field]').click
    end

    it 'will skip collecting case info' do
      click_button 'Update'
      expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code))
    end

    it 'can save and allocate' do
      click_button 'Save and Allocate'
      expect(page).to have_current_path(new_prison_allocation_path(prison.code, prisoner_id))
    end
  end

  context 'when complexity level is present' do
    before do
      allow(ComplexityMicroService).to receive(:get_complexity).with(prisoner_id).and_return('medium')
    end

    it 'will skip collecting complexity' do
      visit missing_information_prison_prisoners_path prison.code
      click_link 'Add missing details'

      find('label[for=case-information-welsh-offender-no-field]').click
      find('label[for=case-information-case-allocation-nps-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Update'
      wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
    end
  end
end
