describe 'layouts/_nav_link' do
  let(:text) { 'link text' }
  let(:path) { '/test/123' }
  let(:resulting_link) { Nokogiri::HTML(rendered).at('a.moj-primary-navigation__link') }

  context 'when the given link is the current page' do
    before { allow(view).to receive(:current_page?).with(path).and_return(true) }

    it 'sets aria current page to true' do
      render('layouts/nav_link', path:, text:)
      expect(resulting_link.attr('aria-current')).to eq('page')
    end
  end

  context 'when the given link is not the current page' do
    before { allow(view).to receive(:current_page?).with(path).and_return(false) }

    it 'leaves aria current page unset' do
      render('layouts/nav_link', path:, text:)
      expect(resulting_link.attr('aria-current')).to be_nil
    end
  end
end
