describe 'layouts/_primary_navigation' do
  before do
    assign(:is_spo, is_spo)
    assign(:is_pom, is_pom)
    assign(:staff_id, 123)
    assign(:prison, double(code: 'LEI'))
    render
  end

  let(:page) { Nokogiri::HTML(rendered) }
  let(:nav_links) { page.css('.moj-primary-navigation__link').map(&:text) }

  context 'with an SPO user' do
    let(:is_spo) { true }
    let(:is_pom) { false }

    it 'displays header links relevent to an SPOs tasks' do
      expect(nav_links).to eq([I18n.t('service_name'), "Allocations", "Parole", "Handover", "Staff"])
    end
  end

  context 'with a POM user' do
    let(:is_spo) { false }
    let(:is_pom) { true }

    it 'displays header links relevent to a POMs tasks' do
      expect(nav_links).to eq([I18n.t('service_name'), "Caseload", "Handover"])
    end
  end

  context 'with an SPO / POM user' do
    let(:is_spo) { true }
    let(:is_pom) { true }

    it 'displays all header links for both roles' do
      expect(nav_links).to eq([I18n.t('service_name'), "Allocations", "Caseload", "Parole", "Handover", "Staff"])
    end
  end
end
