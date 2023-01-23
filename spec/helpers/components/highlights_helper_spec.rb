# frozen_string_literal: true

RSpec.describe Components::HighlightsHelper, type: :helper do
  describe '#highlight_tag' do
    before do
      allow(helper).to receive(:capture)
      allow(helper.tag).to receive(:div)
    end

    it 'builds text content tags' do
      helper.highlight_tag('primary', 'notice', 'content')
      expect(helper.tag).to have_received(:div).with('content', class: anything)
    end

    it 'builds block content tags' do
      allow(helper).to receive(:capture).and_yield
      expected_block = proc {}
      helper.highlight_tag('primary', 'notice', &expected_block)
      expect(helper.tag).to have_received(:div).with(class: anything) do |&block|
        expect(block).to be(expected_block)
      end
    end

    it 'adds correct classes' do
      helper.highlight_tag('primary', 'notice', 'content', more_classes: %w[a b])
      expect(helper.tag).to have_received(:div).with(anything, class: %w[highlight-primary highlight-notice a b])
    end

    it 'allows valid type/level combinations' do
      aggregate_failures do
        expect { helper.highlight_tag('primary', 'notice', 'content') }.not_to raise_error
        expect { helper.highlight_tag('primary', 'alert', 'content') }.not_to raise_error
        expect { helper.highlight_tag('secondary', 'notice', 'content') }.not_to raise_error
        expect { helper.highlight_tag('secondary', 'alert', 'content') }.not_to raise_error
      end
    end

    it 'does not allow invalid type or levels' do
      aggregate_failures do
        expect { helper.highlight_tag('primary', 'badlevel', 'content') }.to raise_error(ArgumentError)
        expect { helper.highlight_tag('badtype', 'notice', 'content') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#highlight_conditionally' do
    it 'renders correct HTML if highlight condition is set' do
      result = helper.highlight_conditionally('notice', 'secondary text', -> { true }) do
        concat('primary text')
      end

      expect(result).to eq '<div class="highlight-primary highlight-notice">primary text</div>' \
                           '<div class="highlight-secondary highlight-notice">secondary text</div>'
    end

    it 'renders correct HTML if highlight condition not set' do
      result = helper.highlight_conditionally('alert', 'xx', -> { false }) do
        concat('primary text')
      end

      expect(result).to eq 'primary text'
    end
  end
end
