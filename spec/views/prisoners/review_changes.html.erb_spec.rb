require 'rails_helper'

RSpec.describe 'prisoners/review_changes', type: :view do
  let(:prison) { build(:prison) }
  let(:prisoner) do
    instance_double(MpcOffender, full_name_ordered: 'Test Offender', offender_no: 'A1234BC',
                                 date_of_birth: Date.new(1980, 2, 22), age: 46,
                                 first_name: 'Test', immigration_case?: false, pom_responsible?: true,
                                 tier: 'B', rosh_level: 'HIGH',
                                 recommended_pom_type: RecommendationService::PROBATION_POM,
                                 earliest_release: { type: :conditional_release_date, date: Date.new(2028, 1, 14) })
  end
  let(:changes) do
    [:rosh, :tier, :handover].map do |type|
      instance_double(SignificantChanges::ChangePresenter, type:, title: "#{type} title",
                                                           changed_at: "#{type} date",
                                                           from_value: "#{type} previous value",
                                                           to_value: "#{type} current value",
                                                           explanation: type == :handover ? 'Handover explanation' : nil)
    end
  end
  let(:page) { Capybara.string(rendered) }

  before do
    assign(:prison, prison)
    assign(:prisoner, prisoner)
    assign(:changes, changes)
    assign(:review, instance_double(SignificantChanges,
                                    allocation: build(:allocation_history, primary_pom_name: 'Pom, Example'),
                                    allocated_pom_position: RecommendationService::PRISON_POM))
    render
  end

  it 'shows the prisoner details and a back link to the review list' do
    expect(page).to have_css('h1', text: 'Review allocation for Test Offender', normalize_ws: true, exact_text: true)
    expect(page).to have_text('Prison number: A1234BC')
    expect(page).to have_text('Date of birth: 22 Feb 1980 (46)')
    expect(page).to have_link('Back', href: review_allocations_prison_prisoners_path(prison))
  end

  it 'shows the change cards in the supplied order with their dates and values' do
    cards = page.all('[aria-labelledby^="review-change-"]')
    expect(cards.map { it.find('h2').text.squish }).to eq(['rosh title', 'tier title', 'handover title'])
    [:rosh, :tier, :handover].each_with_index do |type, index|
      expect(cards[index].all('.govuk-summary-list__key').map(&:text)).to eq(['Date of change', 'Changed from', 'Changed to'])
      expect(cards[index].all('.govuk-summary-list__value').map(&:text)).to eq(
        ["#{type} date", "#{type} previous value", "#{type} current value"]
      )
    end
  end

  it 'renders an explanation paragraph only when the presenter supplies one' do
    expect(page).to have_css('.govuk-summary-card__content > p', count: 1)
    handover = page.find('[aria-labelledby="review-change-handover"]')
    expect(handover).to have_css('p.govuk-body', text: 'Handover explanation', exact_text: true)
  end

  it 'labels each change card with its heading' do
    cards = page.all('[aria-labelledby^="review-change-"]')
    expect(cards.map { it.find('h2')['id'] }).to eq(cards.map { it['aria-labelledby'] })
  end

  it 'links to the existing reallocation journey with a primary button below the cards' do
    expect(page).to have_css(
      '.govuk-summary-card ~ .govuk-button-group a.govuk-button[role="button"][data-module="govuk-button"]',
      text: 'Reallocate', exact_text: true
    )
    expect(page).to have_link('Reallocate', href: prison_prisoner_review_case_details_path(prison.code, prisoner.offender_no))
    expect(page).to have_link('Keep current allocation', href: new_prison_prisoner_allocation_retention_path(prison.code, prisoner.offender_no))
  end

  it 'shows the recommendation and current case details between the changes and the buttons' do
    expect(page).to have_css('h2.govuk-heading-l', text: 'Do you want to reallocate to a different type of POM?')
    expect(page).to have_css('h3', text: 'Probation POM recommended')
    expect(page).to have_css('.govuk-inset-text', text: 'Test has a high ROSH, so we recommend allocating to a probation POM.')
    expect(page).to have_css('.govuk-inset-text strong', text: 'probation POM')
    details = page.find('[aria-labelledby="review-case-details"]')
    expect(details).to have_text('Case details')
    expect(details.all('dt').map(&:text)).to eq(['Current POM name', 'Current POM type', 'Earliest release date'])
    expect(details).to have_text('Example Pom')
    expect(details).to have_text('Prison POM')
    expect(details).to have_text('14 January 2028')
    expect(page).to have_css('[aria-labelledby^="review-change-"] ~ h2 ~ .govuk-summary-card ~ .govuk-button-group')
  end

  it 'omits source attribution and card actions' do
    expect(page).to have_no_text('Where the change happened')
    expect(page).to have_no_css('.govuk-summary-list__actions')
  end

  context 'when only a tier change is outstanding' do
    let(:changes) { super().select { it.type == :tier } }

    it 'only renders the supplied card' do
      expect(page).to have_css('[aria-labelledby^="review-change-"]', count: 1)
      expect(page).to have_css('#review-change-tier')
      expect(page).to have_no_css('#review-change-rosh, #review-change-handover')
    end
  end
end
