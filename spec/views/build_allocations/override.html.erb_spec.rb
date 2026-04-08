# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'build_allocations/override', type: :view do
  let(:page) { Capybara.string(rendered) }
  let(:override) do
    OverrideForm.new(override_reasons: ['other']).tap(&:valid?)
  end
  let(:pom) do
    instance_double(StaffMember, full_name_ordered: 'Jessica King', position: 'PO')
  end
  let(:prisoner) do
    instance_double(
      MpcOffender,
      full_name_ordered: 'Christopher Hamilton',
      offender_no: 'G4198UW',
      immigration_case?: false,
      pom_responsible?: true,
      tier: 'C'
    )
  end

  before do
    assign(:override, override)
    assign(:pom, pom)
    assign(:prisoner, prisoner)
    view.define_singleton_method(:wizard_path) { '/wizard/override' }
  end

  it 'uses the shared override markup' do
    render

    expect(page).to have_css('.govuk-grid-column-two-thirds')
    expect(page).to have_css('.govuk-error-summary')
    expect(page).to have_css('form[action="/wizard/override"]')
    expect(page).to have_css('h1.govuk-heading-l', text: 'Why are you allocating a probation POM to Christopher Hamilton (G4198UW)?')
    expect(page).to have_css('.govuk-hint', text: 'Choose all that apply')
    expect(page).to have_text('Other reason')
    expect(page).to have_text('Jessica King has worked with Christopher Hamilton before')
    expect(page).to have_css('textarea#override-form-more-detail-field-error')
    expect(page).to have_css('input[value="other"][checked]')
  end
end
