require 'rails_helper'

feature 'Navigation', vcr: { cassette_name: :navigation } do
  let(:prison) { build(:prison, code: 'LEI') }
  let(:link_css) { '.moj-primary-navigation__link' }
  let(:nav_links) { all(link_css) }

  context 'with an SPO user' do
    before do
      signin_spo_user
      visit prison_dashboard_index_path(prison.code)
    end

    it 'has an SPO menu' do
      expect(nav_links.map(&:text)).to eq(["Home", "Allocations", "Handover", "Staff"])
    end
  end

  context 'with a POM user' do
    before do
      signin_pom_user
      visit prison_dashboard_index_path(prison.code)
    end

    it 'has a POM menu' do
      expect(nav_links.map(&:text)).to eq(["Home", "Caseload", "Handover"])
    end
  end

  context 'with a POM/SPO user' do
    before do
      signin_spo_pom_user
      visit prison_dashboard_index_path(prison.code)
    end

    it 'has a POM/SPO menu' do
      expect(nav_links.map(&:text)).to eq(["Home", "Allocations", "Caseload", "Handover", "Staff"])
    end

    it 'highlights the current page' do
      all(link_css).each_with_index do |_link, index|
        link = all(link_css)[index]
        link.click
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
      end
    end
  end
end
