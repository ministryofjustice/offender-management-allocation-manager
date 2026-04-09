# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reallocations/override', type: :view do
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
  let(:override_case) do
    instance_double(
      AllocatedOffender,
      full_name_ordered: 'Bob Amber',
      nomis_offender_id: 'G5678BB'
    )
  end
  let(:override_prisoner) do
    instance_double(
      MpcOffender,
      full_name_ordered: 'Bob Amber',
      immigration_case?: false,
      pom_responsible?: true,
      tier: 'C'
    )
  end

  before do
    stub_poms(prison.code, all_pom_records)
    stub_offenders_for_prison(prison.code, [])

    view.request.path_parameters[:prison_id] = prison.code
    view.request.path_parameters[:nomis_staff_id] = source_pom.staff_id
    view.request.path_parameters[:new_pom] = target_pom.staff_id
    view.request.path_parameters[:nomis_offender_id] = override_case.nomis_offender_id

    assign(:prison, prison)
    assign(:pom, source_pom)
    assign(:new_pom, target_pom)
    assign(:override_case, override_case)
    assign(:override_prisoner, override_prisoner)
    assign(:cases_remaining, 5)
    assign(:back_path, '/back')
  end

  context 'when no reasons are selected' do
    before do
      override = OverrideForm.new(override_reasons: nil)
      override.valid?
      assign(:override, override)
    end

    it 'links the error summary to the first checkbox' do
      render

      expect(page).to have_css('.govuk-error-summary')
      expect(page).to have_css('.govuk-hint', text: 'Choose all that apply')
      expect(page).to have_link(
        'Select one or more reasons for not accepting the recommendation',
        href: '#override-form-override-reasons-field-error'
      )
      expect(page).to have_css('input#override-form-override-reasons-field-error')
    end

    it 'renders the error summary below the back link and above the page heading' do
      render

      back_link_position = rendered.index('href="/back"')
      error_summary_position = rendered.index('govuk-error-summary')
      heading_position = rendered.index('Why are you allocating a probation POM to Bob Amber (G5678BB)?')

      expect(back_link_position).to be < error_summary_position
      expect(error_summary_position).to be < heading_position
    end

    it 'renders the error summary in the same width container as the form content' do
      render

      expect(page).to have_css('.govuk-grid-column-two-thirds .govuk-error-summary')
    end

    it 'does not show the cases remaining caption' do
      render

      expect(rendered).not_to include('Cases remaining:')
    end
  end

  context 'when other is selected without detail' do
    before do
      override = OverrideForm.new(override_reasons: ['other'])
      override.valid?
      assign(:override, override)
    end

    it 'links the error summary to the other reason textarea' do
      render

      expect(page).to have_link(
        'Please provide extra detail when Other is selected',
        href: '#override-form-more-detail-field-error'
      )
      expect(page).to have_css('input[value="other"][checked]')
      expect(page).to have_css('textarea#override-form-more-detail-field-error')
    end
  end

  context 'when suitability is selected without detail' do
    before do
      override = OverrideForm.new(override_reasons: ['suitability'])
      override.valid?
      assign(:override, override)
    end

    it 'links the error summary to the suitability detail textarea' do
      render

      expect(page).to have_link(
        'Enter reason for allocating this POM',
        href: '#override-form-suitability-detail-field-error'
      )
      expect(page).to have_css('input[value="suitability"][checked]')
      expect(page).to have_css('textarea#override-form-suitability-detail-field-error')
    end
  end
end
