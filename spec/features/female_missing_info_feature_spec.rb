# frozen_string_literal: true

require "rails_helper"

feature "womens missing info journey" do
  let(:prison) { create(:womens_prison) }
  let(:offenders) { build_list(:nomis_offender, 2, prisonId: prison.code, complexityLevel: complexity) }
  let(:offender) { offenders.first }
  let(:prisoner_id) { offender.fetch(:prisonerNumber) }
  let(:second_prisoner_id) { offenders.last.fetch(:prisonerNumber) }
  let(:user) { build(:pom) }
  let(:username) { 'MOIC_POM' }

  before do
    stub_signin_spo user, [prison.code]
    stub_poms(prison.code, [user])
    stub_offenders_for_prison(prison.code, offenders)
  end

  context 'without any data' do
    let(:complexity) { nil }

    before do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(prisoner_id, level: 'low', username: username, reason: nil)
    end

    it 'has a happy path', js: true do
      visit missing_information_prison_prisoners_path prison.code
      within "#edit_#{prisoner_id}" do
        click_link 'Add missing details'
      end
      # bang the update button - expect a big red error message
      click_button 'Update'
      within '.govuk-error-summary' do
        expect(all('li').map(&:text))
          .to match_array(["You must choose a complexity level"])
      end

      find('label[for=complexity-form-complexity-level-low-field]').click

      click_button 'Update'
      expect {
        #  again should have lots of error messages
        click_button 'Update'
        within '.govuk-error-summary' do
          expect(all('li').map(&:text))
            .to match_array(
              [
                "Select the prisoner’s tier",
              ])
        end

        # There are some subtleties here - the first field has been renamed (e.g) case-information-welsh-offender-field-error
        # so pick the second one to avoid the noise
        find('label[for=case-information-enhanced-resourcing-false-field]').click
        find('label[for=case-information-tier-b-field]').click
        click_button 'Update'
        wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
      }.to change(CaseInformation, :count).by(1)
    end
  end

  context 'when case information is present' do
    let(:complexity) { nil }

    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: prisoner_id))
      expect(HmppsApi::ComplexityApi).to receive(:save).with(prisoner_id, level: 'medium', username: username, reason: nil)

      visit missing_information_prison_prisoners_path prison.code
      within "#edit_#{prisoner_id}" do
        click_link 'Add missing details'
      end

      find('label[for=complexity-form-complexity-level-medium-field]').click
    end

    it 'will skip collecting case info' do
      click_button 'Update'
      expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code))
    end

    it 'can save and allocate' do
      # Need to update the mocked offender with the updated complexity level to mimic the selection from the
      # complexity level radio buttons
      offender[:complexityLevel] = 'medium'
      stub_offender(offender)

      click_button 'Save and Allocate'
      expect(page).to have_current_path(prison_prisoner_staff_index_path(prison.code, prisoner_id))
    end
  end

  context 'when complexity level is present' do
    let(:complexity) { 'medium' }

    it 'will skip collecting complexity' do
      visit missing_information_prison_prisoners_path prison.code
      within "#edit_#{prisoner_id}" do
        click_link 'Add missing details'
      end

      find('label[for=case-information-enhanced-resourcing-true-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Update'
      wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
    end
  end

  context 'when multiple tabs are opened', :js do
    # Complexity is prefilled so that this part of the journey does not have to be implemented
    # It would have required an extra stub_request for complexity level
    let(:complexity) { 'medium' }

    it 'can complete forms in parallel' do
      visit missing_information_prison_prisoners_path prison.code

      within "#edit_#{prisoner_id}" do
        click_link 'Add missing details'
      end

      execute_in_new_tab do
        visit missing_information_prison_prisoners_path prison.code

        within "#edit_#{second_prisoner_id}" do
          click_link 'Add missing details'
        end

        fill_in_missing_case_information
      end

      fill_in_missing_case_information

      # check both updates work
      expect(CaseInformation.find_by(nomis_offender_id: prisoner_id)).not_to be_nil
      expect(CaseInformation.find_by(nomis_offender_id: second_prisoner_id)).not_to be_nil
    end

    def fill_in_missing_case_information
      find('label[for=case-information-enhanced-resourcing-true-field]').click
      find('label[for=case-information-tier-a-field]').click

      click_button 'Update'
    end
  end
end
