require 'rails_helper'

RSpec.describe 'prisoners/review_changes', type: :view do
  let(:prison) { build(:prison) }
  let(:prisoner) do
    instance_double(MpcOffender, full_name_ordered: 'John Doe', offender_no: 'A1234BC',
                                 date_of_birth: Date.new(1980, 2, 22), age: 46)
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
    render
  end

  it 'shows the prisoner details and a back link to the review list' do
    expect(page).to have_css('h1', text: 'Review allocation for John Doe', normalize_ws: true, exact_text: true)
    expect(page).to have_text('Prison number: A1234BC')
    expect(page).to have_text('Date of birth: 22 Feb 1980 (46)')
    expect(page).to have_link('Back', href: review_allocations_prison_prisoners_path(prison))
  end

  it 'shows the change cards in the supplied order with their dates and values' do
    cards = page.all('.govuk-summary-card')
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

  it 'uses the GDS summary card structure with labelled headings' do
    expect(page).to have_css('div.govuk-summary-card', count: 3)
    cards = page.all('div.govuk-summary-card')
    expect(cards).to all(have_css('.govuk-summary-card__title-wrapper > h2.govuk-summary-card__title'))
    expect(cards.map { it.find('h2')['id'] }).to eq(cards.map { it['aria-labelledby'] })
    expect(cards).to all(have_css('.govuk-summary-card__content > dl.govuk-summary-list', count: 1))
    expect(cards).to all(have_css('dl.govuk-summary-list > div.govuk-summary-list__row > dt.govuk-summary-list__key', count: 3))
    expect(cards).to all(have_css('dl.govuk-summary-list > div.govuk-summary-list__row > dd.govuk-summary-list__value', count: 3))
  end

  it 'links to the existing reallocation journey with a primary button below the cards' do
    expect(page).to have_css(
      '.govuk-summary-card ~ .govuk-button-group a.govuk-button[role="button"][data-module="govuk-button"]',
      text: 'Reallocate', exact_text: true
    )
    expect(page).to have_link('Reallocate', href: prison_prisoner_review_case_details_path(prison.code, prisoner.offender_no))
    expect(page).to have_no_css('.govuk-button--secondary')
  end

  it 'omits source attribution and card actions' do
    expect(page).to have_no_text('Where the change happened')
    expect(page).to have_no_css('.govuk-summary-list__actions')
  end

  context 'when only a tier change is outstanding' do
    let(:changes) { super().select { it.type == :tier } }

    it 'only renders the supplied card' do
      expect(page).to have_css('.govuk-summary-card', count: 1)
      expect(page).to have_css('#review-change-tier')
      expect(page).to have_no_css('#review-change-rosh, #review-change-handover')
    end
  end
end
