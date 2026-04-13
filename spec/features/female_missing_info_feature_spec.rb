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

  include_context 'with missing information feature defaults'

  context 'without any data' do
    let(:complexity) { nil }

    before do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(prisoner_id, level: 'low', username: username, reason: nil)
    end

    it 'has a happy path through complexity and shared case information', js: true do
      start_missing_information_journey(prison_code: prison.code, prisoner_id: prisoner_id)

      expect(page).to have_content('Add complexity of need level')
      expect(page).to have_button('Save and continue')
      expect(page).to have_no_button('Save and allocate')

      # bang the save and continue button - expect a big red error message
      click_button 'Save and continue'
      within '.govuk-error-summary' do
        expect(all('li').map(&:text))
          .to match_array(["Select complexity of need"])
      end

      find('label[for=complexity-form-complexity-level-low-field]').click

      click_button 'Save and continue'

      expect_case_information_page(
        prison_code: prison.code,
        prisoner_id: prisoner_id,
        expected_path: new_prison_prisoner_case_information_path(prison.code, prisoner_id)
      )

      expect {
        click_button 'Save'
        within '.govuk-error-summary' do
          expect(page).to have_content('Select tier')
          expect(page).to have_content('Select case allocation decision')
        end

        fill_in_case_information(resourcing: 'false', tier: 'B')
        click_button 'Save'
        wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
      }.to change(CaseInformation, :count).by(1)
    end
  end

  context 'when case information is present' do
    let(:complexity) { nil }

    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: prisoner_id))

      start_missing_information_journey(prison_code: prison.code, prisoner_id: prisoner_id)

      find('label[for=complexity-form-complexity-level-medium-field]').click
    end

    it 'shows save and allocate when complexity is the final missing step' do
      expect(page).to have_button('Save and allocate')
      expect(page).to have_no_button('Save and continue')
    end

    it 'can save and allocate' do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(prisoner_id, level: 'medium', username: username, reason: nil)

      # Need to update the mocked offender with the updated complexity level to mimic the selection from the
      # complexity level radio buttons
      offender[:complexityLevel] = 'medium'
      stub_offender(offender)

      click_button 'Save and allocate'
      expect(page).to have_current_path(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: prisoner_id))
    end
  end

  context 'when complexity level is present' do
    let(:complexity) { 'medium' }

    it 'will skip collecting complexity and use the shared case information form' do
      start_missing_information_journey(prison_code: prison.code, prisoner_id: prisoner_id)

      expect_case_information_page(prison_code: prison.code, prisoner_id: prisoner_id)

      fill_in_case_information(resourcing: 'true', tier: 'A')
      click_button 'Save'
      wait_for { page.current_path == missing_information_prison_prisoners_path(prison.code) }
    end

    it 'redirects straight to case information when the female missing info route is hit directly' do
      visit new_prison_prisoner_female_missing_info_path(prison.code, prisoner_id)

      expect(page).to have_current_path(new_prison_prisoner_case_information_path(prison.code, prisoner_id), ignore_query: true)
      expect(page).to have_content('Add missing details for')
      expect(page).to have_no_content('Add complexity of need level')
    end
  end

  context 'when multiple tabs are opened', :js do
    # Complexity is prefilled so that this part of the journey does not have to be implemented
    # It would have required an extra stub_request for complexity level
    let(:complexity) { 'medium' }

    it 'can complete forms in parallel' do
      start_missing_information_journey(prison_code: prison.code, prisoner_id: prisoner_id)

      execute_in_new_tab do
        start_missing_information_journey(prison_code: prison.code, prisoner_id: second_prisoner_id)

        fill_in_missing_case_information
      end

      fill_in_missing_case_information

      # check both updates work
      expect(CaseInformation.find_by(nomis_offender_id: prisoner_id)).not_to be_nil
      expect(CaseInformation.find_by(nomis_offender_id: second_prisoner_id)).not_to be_nil
    end

    def fill_in_missing_case_information
      fill_in_case_information(resourcing: 'true', tier: 'A')
      click_button 'Save'
    end
  end
end
