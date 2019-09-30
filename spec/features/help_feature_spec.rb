require 'rails_helper'

feature 'Help' do
  context 'when accessing help page' do
    it 'provides a link to the help pages', vcr: { cassette_name: :help_link } do
      signin_user('PK000223')

      visit '/'
      expect(page).to have_link('Help', href: '/help')
    end
  end

  context 'when visiting help page' do
    it 'has links to help topics', vcr: { cassette_name: :help_page } do
      visit '/help'

      help_topics = [
          ['Getting set up', help_step0_path],
          ['Updating case information', update_case_information_path],
          ['Missing cases', missing_cases_path]
      ]

      help_topics.each do |key, val|
        expect(page).to have_link(key, href: val)
      end
    end
  end

  context 'when viewing getting set up pages' do
    let(:inset_text) do
      { LSA: 'Local System Administrator (LSA) task',
        SPO_HoOMU: 'Senior Probation Officer / Head of Offender Management Unit (SPO/HoOMU) task',
        CASE_ADMIN: 'Senior Probation Officer / Head of Offender Management Unit (SPO/HoOMU) / Case admin task'
      }
    end

    before do
      visit '/help_step0'
    end

    scenario 'getting set up pages', vcr: { cassette_name: :help_getting_set_up_pages } do
      help_links = [
          ['List everyone using the service', 'help_step1'],
          ['Set up access in Digital Prison Services', 'help_step2'],
          ['Set up POMs in NOMIS', 'help_step3'],
          ['Update POM profiles', 'help_step4'],
          ['Update prisoner information', 'help_step5'],
          ['Start making allocations', 'help_step6']
      ]

      help_links.each do |key, val|
        expect(page).to have_link(key, href: val)
      end

      title = 'Overview'

      expect(page).not_to have_link(title)
      expect(page).to have_css('h1', text: title)

      task_links = [
          ['Task 1', 'help_step1'],
          ['Task 2', 'help_step2'],
          ['Task 3', 'help_step3'],
          ['Task 4', 'help_step4'],
          ['Task 5', 'help_step5'],
          ['Task 6', 'help_step6']
      ]

      task_links.each do |key, val|
        expect(page).to have_link(key, href: val)
      end
    end

    scenario 'help getting set up step_1 page', vcr: { cassette_name: :help_getting_set_up_step_1 } do
      title = 'List everyone using the service'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:SPO_HoOMU])
      expect(page).to have_link('spreadsheet template')
      expect(page).to have_xpath("//img[contains(@src,'assets/spreadsheet_image')]")
      expect(page).to have_link('moic@digital.justice.gov.uk')
      expect(page).to have_link('Task 2: Set up access in Digital Prison Services', href: 'help_step2')
    end

    scenario 'help getting set up step_2 page', vcr: { cassette_name: :help_getting_set_up_step_2 } do
      title = 'Set up access in Digital Prison Services'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:LSA])
      expect(page).to have_link('https://notm.service.hmpps.dsd.io/')

      images = %w[hmpps_login_image nomis_login_image admin_util_image search_staff_image staff_member_image staff_roles_image add_staff_image choose_role_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'help getting set up step_3 page', vcr: { cassette_name: :help_getting_set_up_step_3 } do
      title = 'Set up POMs in NOMIS'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:LSA])
      expect(page).to have_link('Task 1: List everyone using the service', href: 'help_step1')
      expect(page).to have_link('Task 4: Update POM profiles', href: 'help_step4')

      images = %w[caseload2_image search_box_image action_toolbar_image caseload1_image search_box_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'help getting set up step_4 page', vcr: { cassette_name: :help_getting_set_up_step_4 } do
      title = 'Update POM profiles'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:CASE_ADMIN])
      expect(page).to have_link('Task 2: Set up access in Digital Prison Services', href: 'help_step2')
      expect(page).to have_link('https://moic.service.justice.gov.uk')
    end

    scenario 'help getting set up step_5 page', vcr: { cassette_name: :help_getting_set_up_step_5 } do
      title = 'Update prisoner information'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:CASE_ADMIN])
      expect(page).to have_link('Task 3: Set up POMs in NOMIS', href: 'help_step3')
      expect(page).to have_link('https://moic.service.justice.gov.uk')
      expect(page).to have_link('Home', href: '/')
    end

    scenario 'help getting set up step_6 page', vcr: { cassette_name: :help_getting_set_up_step_6 } do
      title = 'Start making allocations'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:SPO_HoOMU])
      expect(page).to have_link('https://moic.service.justice.gov.uk')
    end
  end

  context 'when viewing updating case information page' do
    before do
      visit update_case_information_path
    end

    scenario 'help updating case information overview', vcr: { cassette_name: :help_update_case_info_overview } do
      expect(page).to have_css('h1', text: 'Overview')
      expect(page).to have_link('Updating nDelius', href: updating_ndelius_path)
    end

    scenario 'help updating nDelius', vcr: { cassette_name: :help_update_ndelius } do
      title = 'Updating nDelius'

      click_link(title)

      expect(page).to have_link('Overview', href: update_case_information_path)
      expect(page).to have_css('h1', text: title)
      expect(page).to have_xpath("//img[contains(@src,'assets/ndelius_find_prisoner')]")
      expect(page).to have_xpath("//img[contains(@src,'assets/ndelius_dss_results')]")
      expect(page).to have_xpath("//img[contains(@src,'assets/ndelius_offender_details')]")
    end
  end

  context 'when viewing missing cases page' do
    before do
      visit missing_cases_path
    end

    scenario 'help when no POM allocation needed', vcr: { cassette_name: :help_missing_case_no_pom_allocation } do
      expect(page).to have_link('Repatriated cases', href: repatriated_path)
      expect(page).to have_link('Scottish and Northern Irish prisoners', href: scottish_northern_irish_path)
      expect(page).to have_css('h1', text: 'No POM allocation needed')
      expect(page).to have_link('https://intranet.noms.gsi.gov.uk/corporate/offender-management-model')
      expect(page).to have_link('Contact us', href: contact_us_path)
    end

    scenario 'help with repatriated cases', vcr: { cassette_name: :help_with_repatriated_cases } do
      title = 'Repatriated cases'

      click_link(title)

      expect(page).to have_link('No POM allocation needed', href: missing_cases_path)
      expect(page).to have_css('h1', text: title)
    end

    scenario 'help with scottish/irish prisoners', vcr: { cassette_name: :help_with_scottish_irish } do
      title = 'Scottish and Northern Irish prisoners'

      click_link(title)

      expect(page).to have_css('h1', text: title)
    end
  end
end
