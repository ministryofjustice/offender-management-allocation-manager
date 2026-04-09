# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reallocations/summary', type: :view do
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
  let(:selected_case) do
    instance_double(
      AllocatedOffender,
      full_name: 'Bob Amber',
      nomis_offender_id: 'G5678BB'
    )
  end

  before do
    stub_poms(prison.code, all_pom_records)
    stub_offenders_for_prison(prison.code, [])

    view.request.path_parameters[:prison_id] = prison.code
    view.request.path_parameters[:nomis_staff_id] = source_pom.staff_id
    view.request.path_parameters[:new_pom] = target_pom.staff_id

    assign(:prison, prison)
    assign(:pom, source_pom)
    assign(:new_pom, target_pom)
    assign(:selected_cases, [selected_case])
    assign(:cases_remaining, 4)
    assign(:back_path, '/back')
  end

  context 'when the allocation form has errors' do
    before do
      allocation = AllocationForm.new
      allocation.errors.add(:message, 'Enter a message')
      assign(:allocation, allocation)
    end

    it 'renders the error summary below the back link and above the page heading' do
      render

      back_link_position = rendered.index('href="/back"')
      error_summary_position = rendered.index('govuk-error-summary')
      heading_position = rendered.index('Confirm reallocation of 1 case')

      expect(back_link_position).to be < error_summary_position
      expect(error_summary_position).to be < heading_position
    end

    it 'renders the error summary in the same width container as the form content' do
      render

      expect(page).to have_css('.govuk-grid-column-two-thirds .govuk-error-summary')
      expect(page).to have_link('Enter a message', href: '#allocation-form-message-field-error')
    end

    it 'shows the cases remaining caption' do
      render

      expect(rendered).to include('Cases remaining: 4')
    end
  end
end
