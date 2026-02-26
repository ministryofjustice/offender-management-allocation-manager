require 'rails_helper'

RSpec.describe "shared/_mappa", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:widget) { page.at_css('.mappa-widget') }

  before do
    render partial: 'shared/mappa', locals: { mappa: mappa }
  end

  shared_examples 'a mappa widget' do
    it 'renders an aside with the correct aria-label' do
      expect(widget.name).to eq('aside')
      expect(widget['aria-label']).to eq('MAPPA level')
    end

    it 'always renders the subtitle text' do
      expect(widget).to have_text('Multi-agency public protection arrangements')
    end
  end

  context 'when MAPPA is found' do
    let(:review_date) { Date.new(2024, 10, 15) }
    let(:mappa) do
      {
        status: :found,
        short_description: 'CAT 2/LEVEL 1',
        review_date: review_date,
        start_date: Date.new(2024, 1, 10),
      }
    end

    it_behaves_like 'a mappa widget'

    it 'displays the short description with MAPPA' do
      heading = widget.at_css('h3')
      expect(heading.at_css('strong').text).to eq('CAT 2/LEVEL 1')
      expect(heading.text).to include('MAPPA')
    end

    it 'displays the last updated date using review_date' do
      expect(widget).to have_text("Last updated: #{review_date.to_fs(:rfc822)}")
    end

    it 'renders a visible section break before the date' do
      hr = widget.at_css('hr')
      expect(hr['class']).to include('govuk-section-break--visible')
    end

    context 'when review_date is nil' do
      let(:review_date) { nil }

      it 'does not display the last updated section' do
        expect(widget).not_to have_text('Last updated')
        expect(widget.at_css('hr')).to be_nil
      end
    end
  end

  context 'when MAPPA is not found' do
    let(:mappa) { { status: :not_found, short_description: nil, review_date: nil, start_date: nil } }

    it_behaves_like 'a mappa widget'

    it 'displays NO MAPPA heading' do
      heading = widget.at_css('h3')
      expect(heading.at_css('strong').text).to eq('NO')
      expect(heading.text).to include('MAPPA')
    end

    it 'does not display a last updated date' do
      expect(widget).not_to have_text('Last updated')
    end

    it 'does not display an error message' do
      expect(widget).not_to have_text('Something went wrong')
    end
  end

  context 'when MAPPA status is error' do
    let(:mappa) { { status: :error, short_description: nil, review_date: nil, start_date: nil } }

    it_behaves_like 'a mappa widget'

    it 'displays UNKNOWN MAPPA heading' do
      heading = widget.at_css('h3')
      expect(heading.at_css('strong').text).to eq('UNKNOWN')
      expect(heading.text).to include('MAPPA')
    end

    it 'displays the error message' do
      expect(widget).to have_text('Something went wrong. We are unable to show MAPPA information at this time. Try again later.')
    end

    it 'renders a visible section break before the error message' do
      hr = widget.at_css('hr')
      expect(hr['class']).to include('govuk-section-break--visible')
    end
  end
end
