require 'rails_helper'

RSpec.describe "shared/_rosh", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:widget) { page.at_css('.rosh-widget') }
  let(:rosh) { RoshSummary.send(:new, **rosh_attrs) }

  before do
    render partial: 'shared/rosh', locals: { rosh: rosh }
  end

  shared_examples 'a rosh widget' do
    it 'renders an aside with the correct aria-label' do
      expect(widget.name).to eq('aside')
      expect(widget['aria-label']).to eq('Risk of serious harm summary')
    end

    it 'renders the subtitle text' do
      expect(widget).to have_text('Risk of serious harm')
    end

    it 'includes ROSH in the heading' do
      expect(widget.at_css('h3').text).to include('ROSH')
    end
  end

  context 'when status is :missing' do
    let(:rosh) { RoshSummary.missing }

    it_behaves_like 'a rosh widget'

    it 'displays UNKNOWN LEVEL as the overall heading' do
      expect(widget.at_css('h3 strong').text).to eq('UNKNOWN LEVEL')
    end

    it 'applies the unknown widget class' do
      expect(widget['class']).to include('rosh-widget--unknown')
    end

    it 'displays the missing message' do
      expect(widget.text).to include('A ROSH summary has not been completed for this individual')
      expect(widget.text).to include('Check OASys')
    end

    it 'does not render the risk table' do
      expect(widget.at_css('table')).to be_nil
    end
  end

  context 'when status is :unable' do
    let(:rosh) { RoshSummary.unable }

    it_behaves_like 'a rosh widget'

    it 'displays UNKNOWN LEVEL as the overall heading' do
      expect(widget.at_css('h3 strong').text).to eq('UNKNOWN LEVEL')
    end

    it 'does not apply a modifier widget class' do
      expect(widget['class'].strip).to eq('rosh-widget')
    end

    it 'displays the unable message' do
      expect(widget.text).to include('Something went wrong')
      expect(widget.text).to include('We are unable to show ROSH information at this time')
    end

    it 'does not render the risk table' do
      expect(widget.at_css('table')).to be_nil
    end
  end

  context 'when status is found with full data' do
    let(:last_updated) { Date.new(2024, 6, 15) }
    let(:rosh_attrs) do
      {
        status: :found,
        overall: 'HIGH',
        last_updated: last_updated,
        custody: {
          children: 'low',
          public: 'high',
          known_adult: 'medium',
          staff: 'very_high',
          prisoners: 'low'
        },
        community: {
          children: 'medium',
          public: 'high',
          known_adult: 'low',
          staff: 'very_high',
          prisoners: nil
        }
      }
    end

    it_behaves_like 'a rosh widget'

    it 'displays the overall risk level in the heading' do
      expect(widget.at_css('h3 strong').text).to eq('HIGH')
    end

    it 'applies the correct widget class based on overall level' do
      expect(widget['class']).to include('rosh-widget--high')
    end

    it 'displays the last updated date' do
      expect(widget).to have_text("Last updated: #{last_updated.to_fs(:rfc822)}")
    end

    it 'renders a risk table' do
      expect(widget.at_css('table')).not_to be_nil
    end

    it 'renders both Community and Custody column headers' do
      headers = widget.css('th.govuk-table__header').map(&:text)
      expect(headers).to include('Community', 'Custody')
    end

    it 'renders all five risk-to row labels' do
      labels = widget.css('[data-qa^="riskToLabelValue"]').map(&:text)
      expect(labels).to eq(['Children', 'Public', 'Known adult', 'Staff', 'Prisoners'])
    end

    it 'renders community risk values' do
      community_cells = widget.css('[data-qa^="riskToCommunityValue"]').map(&:text).map(&:strip)
      expect(community_cells).to eq(['Medium', 'High', 'Low', 'Very high', 'N/A'])
    end

    it 'renders custody risk values' do
      custody_cells = widget.css('[data-qa^="riskToCustodyValue"]').map(&:text).map(&:strip)
      expect(custody_cells).to eq(['Low', 'High', 'Medium', 'Very high', 'Low'])
    end

    it 'applies risk-level CSS classes to community cells' do
      community_cells = widget.css('[data-qa^="riskToCommunityValue"]')
      expect(community_cells[0]['class']).to include('rosh-widget__risk--medium')
      expect(community_cells[1]['class']).to include('rosh-widget__risk--high')
    end

    it 'applies risk-level CSS classes to custody cells' do
      custody_cells = widget.css('[data-qa^="riskToCustodyValue"]')
      expect(custody_cells[1]['class']).to include('rosh-widget__risk--high')
      expect(custody_cells[3]['class']).to include('rosh-widget__risk--very-high')
    end

    context 'when last_updated is nil' do
      let(:last_updated) { nil }

      it 'displays Last updated with Not known' do
        expect(widget).to have_text('Last updated: Not known')
      end
    end
  end

  context 'when found with only community data (no custody)' do
    let(:rosh_attrs) do
      {
        status: :found,
        overall: 'MEDIUM',
        last_updated: Date.new(2024, 1, 1),
        custody: nil,
        community: {
          children: 'low',
          public: 'medium',
          known_adult: nil,
          staff: nil,
          prisoners: nil
        }
      }
    end

    it 'renders the Community column header' do
      headers = widget.css('th.govuk-table__header').map(&:text)
      expect(headers).to include('Community')
    end

    it 'does not render the Custody column header' do
      headers = widget.css('th.govuk-table__header').map(&:text)
      expect(headers).not_to include('Custody')
    end

    it 'does not render custody cells' do
      expect(widget.css('[data-qa^="riskToCustodyValue"]')).to be_empty
    end
  end

  context 'when found with only custody data (no community)' do
    let(:rosh_attrs) do
      {
        status: :found,
        overall: 'LOW',
        last_updated: Date.new(2024, 1, 1),
        custody: {
          children: 'low',
          public: 'low',
          known_adult: 'low',
          staff: 'low',
          prisoners: 'low'
        },
        community: nil
      }
    end

    it 'renders the Custody column header' do
      headers = widget.css('th.govuk-table__header').map(&:text)
      expect(headers).to include('Custody')
    end

    it 'does not render the Community column header' do
      headers = widget.css('th.govuk-table__header').map(&:text)
      expect(headers).not_to include('Community')
    end

    it 'does not render community cells' do
      expect(widget.css('[data-qa^="riskToCommunityValue"]')).to be_empty
    end

    it 'applies the low widget class' do
      expect(widget['class']).to include('rosh-widget--low')
    end
  end

  context 'when found with VERY HIGH overall level' do
    let(:rosh_attrs) do
      {
        status: :found,
        overall: 'VERY_HIGH',
        last_updated: Date.new(2024, 1, 1),
        custody: nil,
        community: nil
      }
    end

    it 'applies the very-high widget class' do
      expect(widget['class']).to include('rosh-widget--very-high')
    end

    it 'displays the overall risk level in the heading' do
      expect(widget.at_css('h3 strong').text).to eq('VERY HIGH')
    end
  end
end
