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

    it 'highlights the current page via the nav links', :js do
      all(link_css).each_with_index do |_link, index|
        # need to re-query a lot as page will be continually re-rendering
        link = click_menu_and_wait(link_css, index)
        expect(link['aria-current']).to eq('page'), "Failed to find current for #{link.text}"
      end
    end

    context 'when in the staff section', :js do
      let(:index) { 4 }

      it 'highlights the section' do
        all(link_css)[index].click
        sleep 2
        within '.probation_pom_row_0' do
          click_link_and_wait 'View'
        end
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
        click_link 'Edit profile'
        sleep 2
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
      end
    end

    context 'when in the caseload section' do
      let(:index) { 2 }

      before do
        create(:allocation, primary_pom_nomis_id: 485926, nomis_offender_id: 'G4273GI')
      end

      it 'highlights the section' do
        all(link_css)[index].click
        click_link 'Abbella, Ozullirn'
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
      end
    end

    context 'when in the allocations section' do
      let(:index) { 1 }

      before do
        create(:case_information, nomis_offender_id: 'G4273GI')
        create(:allocation, primary_pom_nomis_id: 485926, nomis_offender_id: 'G4273GI')
        create(:case_information, nomis_offender_id: 'G8668GF')
      end

      it 'highlights the section', :js do
        click_menu_and_wait(link_css, index)
        click_link_and_wait 'Allocate'
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
      end
    end
  end

  def click_menu_and_wait(link_css, index)
    all(link_css)[index].click
    sleep 3
    all(link_css)[index]
  end

  def click_link_and_wait(text)
    click_link text
    sleep 2
  end
end
