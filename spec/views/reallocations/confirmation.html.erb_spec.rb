# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reallocations/confirmation', type: :view do
  let(:page) { Capybara.string(rendered) }
  let(:prison) { create(:prison) }
  let(:source_pom_record) do
    build(:pom,
          :prison_officer,
          staffId: 10_001,
          firstName: 'Source',
          lastName: 'Pom')
  end
  let(:target_pom_record) do
    build(:pom,
          :probation_officer,
          staffId: 10_002,
          firstName: 'Target',
          lastName: 'Pom')
  end
  let(:all_pom_records) { [source_pom_record, target_pom_record] }
  let(:source_pom) { StaffMember.new(prison, source_pom_record.staff_id) }
  let(:target_pom) { StaffMember.new(prison, target_pom_record.staff_id) }
  let(:selected_cases) do
    [
      { full_name: 'Zephyr, Alice', nomis_offender_id: 'G1234AA', allocated_pom_role: 'Responsible' },
      { full_name: 'Amber, Bob', nomis_offender_id: 'G5678BB', allocated_pom_role: 'Supporting' },
    ]
  end
  let(:failed_cases) { [] }
  let(:message) { 'Some notes' }
  let(:remaining_cases_count) { 3 }

  before do
    stub_poms(prison.code, all_pom_records)
    stub_offenders_for_prison(prison.code, [])

    view.request.path_parameters[:prison_id] = prison.code
    view.request.path_parameters[:nomis_staff_id] = source_pom.staff_id
    view.request.path_parameters[:new_pom] = target_pom.staff_id

    assign(:prison, prison)
    assign(:pom, source_pom)
    assign(:new_pom, target_pom)
    assign(:selected_cases, selected_cases)
    assign(:failed_cases, failed_cases)
    assign(:message, message)
    assign(:remaining_cases_count, remaining_cases_count)

    render
  end

  context 'when cases were successfully reallocated' do
    it 'shows the success panel' do
      expect(page).to have_css('.govuk-panel__title', text: 'Cases reallocated')
    end

    it 'shows the reallocation details' do
      expect(rendered).to include('You have reallocated 2 cases from')
      expect(rendered).to include('Source Pom')
      expect(rendered).to include('Target Pom')
    end

    it 'lists each reallocated case with name, NOMIS ID, and role' do
      expect(page).to have_css('li', text: 'Zephyr, Alice (G1234AA) – responsible', visible: :all)
      expect(page).to have_css('li', text: 'Amber, Bob (G5678BB) – supporting', visible: :all)
    end

    it 'shows the additional notes when a message is present' do
      expect(page).to have_css('strong', text: 'Additional notes:', visible: :all)
      expect(rendered).to include('Some notes')
    end

    it 'shows the copy-to-clipboard button' do
      expect(page).to have_button('Copy this information', visible: :all)
    end
  end

  context 'when there is no message' do
    let(:message) { nil }

    it 'does not show additional notes' do
      expect(rendered).not_to include('Additional notes:')
    end
  end

  describe 'email update section' do
    it 'shows the "Update sent" heading' do
      expect(page).to have_css('h2', text: 'Update sent')
    end

    context 'when both POMs have email addresses' do
      it 'confirms emails were sent to both' do
        expect(rendered).to include(
          "We have emailed Target Pom and Source Pom about the reallocations."
        )
      end
    end

    context 'when only the new POM has an email address' do
      let(:source_pom_record) do
        build(:pom,
              :prison_officer,
              staffId: 10_001,
              firstName: 'Source',
              lastName: 'Pom',
              primaryEmail: nil,
              emails: [])
      end

      it 'says no email was sent to the source POM' do
        expect(rendered.squish).to include(
          'No email was sent to Source Pom because they do not have a registered email address in NOMIS.'
        )
      end
    end

    context 'when only the source POM has an email address' do
      let(:target_pom_record) do
        build(:pom,
              :probation_officer,
              staffId: 10_002,
              firstName: 'Target',
              lastName: 'Pom',
              primaryEmail: nil,
              emails: [])
      end

      it 'says no email was sent to the new POM' do
        expect(rendered.squish).to include(
          'No email was sent to Target Pom because they do not have a registered email address in NOMIS.'
        )
      end
    end

    context 'when neither POM has an email address' do
      let(:source_pom_record) do
        build(:pom,
              :prison_officer,
              staffId: 10_001,
              firstName: 'Source',
              lastName: 'Pom',
              primaryEmail: nil,
              emails: [])
      end
      let(:target_pom_record) do
        build(:pom,
              :probation_officer,
              staffId: 10_002,
              firstName: 'Target',
              lastName: 'Pom',
              primaryEmail: nil,
              emails: [])
      end

      it 'says no emails were sent' do
        expect(rendered).to include('No emails were sent because neither Target Pom nor Source Pom have a')
        expect(rendered).to include('registered email address in NOMIS')
      end
    end
  end

  describe '"What next" section' do
    context 'when there are remaining cases' do
      it 'shows the remaining cases count and reallocate link' do
        expect(rendered).to include('Source Pom has 3 cases left to reallocate.')
        expect(page).to have_link('Reallocate cases now')
        expect(page).to have_link('Back to staff list')
      end
    end

    context 'when there are no remaining cases' do
      let(:remaining_cases_count) { 0 }

      it 'shows the POM has been removed and omits the reallocate link' do
        expect(rendered).to include('Source Pom has no more cases and has been removed from this service.')
        expect(page).not_to have_link('Reallocate cases now')
        expect(page).to have_link('Back to staff list')
      end
    end
  end

  context 'when all cases failed' do
    let(:selected_cases) { [] }
    let(:failed_cases) do
      [
        { full_name: 'Zephyr, Alice', nomis_offender_id: 'G1234AA', error_message: 'API timeout' },
        { full_name: 'Amber, Bob', nomis_offender_id: 'G5678BB', error_message: 'Service down' },
      ]
    end

    it 'shows the failure panel' do
      expect(page).to have_css('.govuk-panel__title', text: 'Reallocation failed')
    end

    it 'does not show the "Update sent" section' do
      expect(page).not_to have_css('h2', text: 'Update sent')
    end

    it 'shows the error summary with all failed cases' do
      expect(rendered).to include('Some cases could not be reallocated')
      expect(rendered).to include('Zephyr, Alice (G1234AA)')
      expect(rendered).to include('Amber, Bob (G5678BB)')
    end
  end

  context 'when some cases failed' do
    let(:selected_cases) do
      [{ full_name: 'Zephyr, Alice', nomis_offender_id: 'G1234AA', allocated_pom_role: 'Responsible' }]
    end
    let(:failed_cases) do
      [{ full_name: 'Amber, Bob', nomis_offender_id: 'G5678BB', error_message: 'API timeout' }]
    end

    it 'shows the success panel' do
      expect(page).to have_css('.govuk-panel__title', text: 'Cases reallocated')
    end

    it 'shows the error summary with the failed case' do
      expect(rendered).to include('One case could not be reallocated')
      expect(rendered).to include('Amber, Bob (G5678BB)')
    end
  end
end
