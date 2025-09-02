describe 'layouts/_controller_nav_link' do
  let(:text) { 'link text' }
  let(:path) { '/test/123' }
  let(:controllers) { {} }
  let(:resulting_link) { Nokogiri::HTML(rendered).at('a.moj-primary-navigation__link') }

  context 'when the given link is the current page' do
    before { allow(view).to receive(:current_page?).with(path).and_return(true) }

    it 'sets aria current page to true' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to eq('page')
    end
  end

  context 'when the given link is not the current page' do
    before { allow(view).to receive(:current_page?).with(path).and_return(false) }

    it 'leaves aria current page unset' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to be_nil
    end
  end

  context 'when controller names are specified and one matches the current controller name' do
    before { allow(view).to receive(:controller_name).and_return('test') }

    let(:controllers) { { test: [], another: [] } }

    it 'sets aria current page to true' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to eq('page')
    end
  end

  context 'when controller names are specified but none match the current controller name' do
    before { allow(view).to receive(:controller_name).and_return('something_else') }

    let(:controllers) { { test: [], another: [] } }

    it 'leaves aria current page unset' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to be_nil
    end
  end

  context 'when controller names and actions are specified and both match the current controller name and action' do
    before do
      allow(view).to receive(:controller_name).and_return('test')
      allow(view).to receive(:action_name).and_return('index')
    end

    let(:controllers) { { test: [:index], another: [] } }

    it 'sets aria current page to true' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to eq('page')
    end
  end

  context 'when controller names and actions are specified and neither match the current controller name or action' do
    before do
      allow(view).to receive(:controller_name).and_return('something_else')
      allow(view).to receive(:action_name).and_return('new')
    end

    let(:controllers) { { test: [:index], another: [] } }

    it 'leaves aria current page unset' do
      render('layouts/controller_nav_link', path:, text:, controllers:)
      expect(resulting_link.attr('aria-current')).to be_nil
    end
  end
end
