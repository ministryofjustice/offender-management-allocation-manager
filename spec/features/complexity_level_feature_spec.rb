require 'rails_helper'

feature 'complexity level feature' do
  let(:offender) { build(:nomis_offender, complexityLevel: 'high', prisonId: womens_prison.code, firstName: 'Sally', lastName: 'Albright') }
  let(:womens_prison) { create(:womens_prison) }
  let(:offenders) { [offender] }
  let(:pom) { build(:pom) }
  let(:spo) { build(:pom) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: womens_prison.code)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))

    stub_offenders_for_prison(womens_prison.code, offenders)
    stub_signin_spo(spo, [womens_prison.code])
    stub_poms(womens_prison.code, [pom, spo])
    stub_keyworker(offender_no)
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return(RoshSummary.missing)
  end

  context 'when on allocation information page' do
    it 'can update the complexity level journey' do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(offender_no, level: 'low', username: "MOIC_POM", reason: 'bla bla bla')

      # Journey starts on prisoner profile page. It should display the existing complexity level and a change link.
      visit prison_prisoner_allocation_path(prisoner_id: offender_no, prison_id: womens_prison.code)

      expect(page).to have_text('Complexity of need level')
      expect(page).to have_css('#complexity-level', text: 'High')
      expect(page).to have_css('#complexity-badge', text: 'High complexity')

      find('td#complexity-level').click_link('Change')

      # Taken to the edit page to update the complexity level
      expect(page).to have_text 'Update complexity of need level'

      # The radio buttons should have the current complexity level checked
      high_radio_button = find('#complexity-level-high-field', visible: false)
      expect(high_radio_button).to be_checked

      # Updated level radio button checked
      find('label[for=complexity-level-low-field]').click
      # Text area left blank
      click_on('Update')
      # Shows errors
      expect(page).to have_css('.govuk-error-message')
      expect(page).to have_text('Enter the reason why the level has changed')

      # Happy path - Textarea Filled in and complexity updated from high to low
      find('textarea#complexity-reason-field-error', visible: false)
      fill_in id: 'complexity-reason-field-error', with: 'bla bla bla'
      click_on('Update')

      # Displays confirmation page
      expect(page).to have_css('#complexity-level-update', text: 'Low')

      # Change the API response to reflect the newly updated level
      stub_request(:get, "#{Rails.configuration.complexity_api_host}/v1/complexity-of-need/offender-no/#{offender_no}")
        .to_return(body: { level: 'low' }.to_json)

      click_on('Return to prisoner page')

      expect(page).to have_current_path(prison_prisoner_allocation_path(prisoner_id: offender_no, prison_id: womens_prison.code), ignore_query: true)
      expect(page).to have_css('#complexity-level', text: 'Low')
      expect(page).to have_css('#complexity-badge', text: 'Low complexity')
    end

    it 'can click back link to return to the prisoner profile page' do
      visit prison_prisoner_allocation_path(prisoner_id: offender_no, prison_id: womens_prison.code)
      find('td#complexity-level').click_link('Change')

      # Taken to the edit page to update the complexity level
      expect(page).to have_text 'Update complexity of need level'

      click_link('Back')
      expect(page).to have_current_path(prison_prisoner_allocation_path(prisoner_id: offender_no, prison_id: womens_prison.code))
    end

    it 'returns straight to allocation information when the level stays the same' do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(offender_no, level: 'high', username: "MOIC_POM", reason: 'No change needed')

      visit prison_prisoner_allocation_path(womens_prison.code, offender_no)

      find('tr#complexity-level-row').click_link('Change')

      fill_in('complexity[reason]', with: 'No change needed')
      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_allocation_path(womens_prison.code, offender_no))
      expect(page).to have_no_css('#complexity-level-update')
      expect(page).to have_css('#complexity-level-row', text: 'High')
    end
  end

  context 'when on review case details' do
    it 'can click the complexity change link and return there after updating' do
      expect(HmppsApi::ComplexityApi).to receive(:save).with(offender_no, level: 'low', username: "MOIC_POM", reason: 'bla bla bla')

      visit prison_prisoner_review_case_details_path(prison_id: womens_prison.code, prisoner_id: offender_no)

      find('#complexity-level-row').click_link('Change')

      expect(page).to have_text 'Update complexity of need level'

      find('label[for=complexity-level-low-field]').click
      fill_in('complexity[reason]', with: 'bla bla bla')

      click_on('Update')

      stub_request(:get, "#{Rails.configuration.complexity_api_host}/v1/complexity-of-need/offender-no/#{offender_no}")
        .to_return(body: { level: 'low' }.to_json)

      click_on('Return to prisoner page')

      expect(page).to have_current_path(prison_prisoner_review_case_details_path(prison_id: womens_prison.code, prisoner_id: offender_no), ignore_query: true)
      expect(page).to have_css('#complexity-level-row', text: 'Complexity of need level')
      expect(page).to have_text('Low')
    end

    it 'keeps the review case details back link after a validation error' do
      visit prison_prisoner_review_case_details_path(prison_id: womens_prison.code, prisoner_id: offender_no)

      find('#complexity-level-row').click_link('Change')

      find('label[for=complexity-level-low-field]').click
      click_on('Update')

      expect(page).to have_text('Enter the reason why the level has changed')

      click_link('Back')

      expect(page).to have_current_path(prison_prisoner_review_case_details_path(prison_id: womens_prison.code, prisoner_id: offender_no), ignore_query: true)
    end
  end
end
