require 'rails_helper'

feature 'Navigation' do
  let(:prison) { build(:prison, code: 'LEI') }
  let(:link_css) { '.moj-primary-navigation__link' }
  let(:nav_links) { all(link_css) }

  # This is a legitimate VCR test - we really don't care how/if the various
  # APIs are called in this test
  describe 'navigation menus', vcr: { cassette_name: 'prison_api/navigation_menus' } do
    context 'with an SPO user' do
      before do
        signin_spo_user
        visit prison_dashboard_index_path(prison.code)
      end

      it 'has an SPO menu' do
        expect(nav_links.map(&:text)).to eq([I18n.t('service_name'), "Allocations", "Parole", "Handover", "Staff"])
      end

      it 'has a help tile' do
        expect(page).to have_css('h3.card__heading a', text: 'Get help with this service')
      end

      it 'has a parole tile' do
        expect(page).to have_css('h3.card__heading a', text: 'Parole cases')
      end
    end

    context 'with a POM user' do
      before do
        signin_pom_user
        visit prison_dashboard_index_path(prison.code)
      end

      it 'has a POM menu' do
        expect(nav_links.map(&:text)).to eq([I18n.t('service_name'), "Caseload", "Handover"])
      end

      it 'has a help tile' do
        expect(page).to have_css('h3.card__heading a', text: 'Get help with this service')
      end

      it 'has a parole tile' do
        expect(page).to have_css('h3.card__heading a', text: 'Parole cases')
      end
    end

    context 'with a POM/SPO user' do
      before do
        signin_spo_pom_user
        visit prison_dashboard_index_path(prison.code)
      end

      it 'has a POM/SPO menu' do
        expect(nav_links.map(&:text)).to eq([I18n.t('service_name'), "Allocations", "Caseload", "Parole", "Handover", "Staff"])
      end

      it 'highlights the current page via the nav links' do
        all(link_css).each_with_index do |_link, index|
          # need to re-query a lot as page will be continually re-rendering
          link = click_menu_and_wait(link_css, index)
          expect(link['aria-current']).to eq('page'), "page link #{link.text} doesn't have aria-current attribute"
        end
      end
    end
  end

  context 'with a POM/SPO user', vcr: { cassette_name: 'prison_api/navigation_pom_spo_things' } do
    before do
      signin_spo_pom_user
      visit prison_dashboard_index_path(prison.code)
    end

    let(:moic_pom_staff_id) { 485_926 }
    let(:offender_no) { 'G7806VO' }
    let(:offender_name) { 'Abdoria, Ongmetain' }

    describe 'staff section' do
      let(:index) { 5 }

      it 'highlights the section' do
        all(link_css)[index].click
        click_link 'Moic Integration-Tests'
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')

        # go into edit the POM profile page
        within first('.govuk-summary-list__row:nth-child(4)') do
          click_link "Change"
        end
        new_link = all(link_css)[index]
        expect(new_link['aria-current']).to eq('page')
      end
    end

    context 'with an allocation', :js do
      before do
        create(:case_information, offender: Offender.find(offender_no))
        create(:allocation_history, prison: prison.code, primary_pom_nomis_id: moic_pom_staff_id, nomis_offender_id: offender_no)
      end

      describe 'caseload section' do
        let(:index) { 2 }

        it 'highlights the section', flaky: true do
          click_menu_and_wait(link_css, index, delay: 5)
          click_link_and_wait 'Your cases (1)'
          expect(page).to have_content offender_name
          click_link_and_wait offender_name
          new_link = all(link_css)[index]
          expect(new_link['aria-current']).to eq('page')
        end
      end
    end
  end

  def click_menu_and_wait(link_css, index, delay: 1)
    link = all(link_css)[index]
    new_page_url = link.native.attribute('href').to_s
    link.click
    # current_path doesn't include the hostname - new_page_url does
    wait_for { new_page_url.ends_with?(current_path) }
    sleep delay
    all(link_css)[index]
  end

  def click_link_and_wait(text, delay: 2)
    link = find(:link, text)
    new_page_url = link.native.attribute('href')
    link.click
    # current_path doesn't include the hostname or the params - new_page_url does
    wait_for { new_page_url.include?(current_path) }
    sleep delay
    # wait_for_turbolinks
  end

  def wait_for_turbolinks
    has_css?('.turbolinks-progress-bar', visible: true)
    has_no_css?('.turbolinks-progress-bar')
  end
end
