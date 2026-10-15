require 'rails_helper'

RSpec.describe 'allocation_retentions/new', type: :view do
  let(:prison) { build(:prison) }
  let(:prisoner) { instance_double(MpcOffender, offender_no: 'A1234BC', full_name_ordered: 'Smith, John') }
  let(:pom) do
    instance_double(StaffMember, full_name_ordered: 'Jones, Jane', position: RecommendationService::PRISON_POM,
                                 prison_officer?: true, probation_officer?: false)
  end
  let(:override) { OverrideForm.new }
  let(:page) { Capybara.string(rendered) }

  before do
    assign(:prison, prison)
    assign(:prisoner, prisoner)
    assign(:pom, pom)
    assign(:override, override)
    render
  end

  it 'uses the same heading, reason fields and button copy as the normal override form' do
    expect(page).to have_css('h1', text: 'Why are you allocating a prison POM to Smith, John (A1234BC)?')
    expect(page).to have_css("form[action='#{prison_prisoner_allocation_retention_path(prison, prisoner.offender_no)}'][method='post']")
    expect(page).to have_field('Assessed as not suitable for a probation POM')
    expect(page).to have_field('No available probation POMs')
    expect(page).to have_field('Jones, Jane has worked with Smith, John before')
    expect(page).to have_field('Other reason')
    expect(page).to have_button('Continue')
    expect(page).to have_link('Back', href: prison_prisoner_review_changes_path(prison, prisoner.offender_no))
  end

  it 'links to case details with a secondary button alongside Continue without submitting the form' do
    group = page.find('.govuk-button-group')

    expect(group).to have_button('Continue')
    expect(group).to have_link('Allocate to someone else',
                               href: prison_prisoner_review_case_details_path(prison, prisoner.offender_no))
    expect(group).to have_css('a.govuk-button--secondary[role="button"][data-module="govuk-button"]',
                              text: 'Allocate to someone else')
  end

  context 'with invalid reasons' do
    let(:override) { OverrideForm.new.tap(&:valid?) }

    it 'renders the validation error summary' do
      expect(page).to have_css('.govuk-error-summary', text: 'Select at least one reason')
    end
  end
end
