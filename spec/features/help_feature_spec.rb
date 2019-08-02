require 'rails_helper'

feature 'Help' do
  context 'when accessing help page' do
    it 'provides a link to the help pages', vcr: { cassette_name: :help_link } do
      signin_user('PK000223')

      visit '/'
      expect(page).to have_link('Help', href: '/help')
    end
  end

  context 'when viewing help pages' do
    before do
      visit '/help'
    end

    scenario 'initial help page', vcr: { cassette_name: :help_initial_page } do
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

      title = 'Get started with the allocations service'

      expect(page).not_to have_link(title)
      expect(page).to have_css("h1", text: title)
      expect(page).to have_link("https://moic.service.justice.gov.uk")
    end

    scenario 'help step_1 page', vcr: { cassette_name: :help_step_1 } do
      title = 'List everyone using the service'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('spreadsheet template')
      expect(page).to have_xpath("//img[contains(@src,'assets/spreadsheet_image')]")
      expect(page).to have_link('hmoic@digital.justice.gov.uk')
      expect(page).to have_link('task 2', href: 'help_step2')
    end

    scenario 'help step_2 page', vcr: { cassette_name: :help_step_2 } do
      title = 'Set up access in Digital Prison Services'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('https://notm.service.hmpps.dsd.io/')

      images = %w[hmpps_login_image nomis_login_image admin_util_image search_staff_image staff_member_image staff_roles_image add_staff_image choose_role_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'help step_3 page', vcr: { cassette_name: :help_step_3 } do
      title = 'Set up POMs in NOMIS'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('task 4', href: 'help_step4')

      images = %w[caseload2_image search_box_image action_toolbar_image caseload1_image search_box_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'help step_4 page', vcr: { cassette_name: :help_step_4 } do
      title = 'Update POM profiles'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('https://moic.service.justice.gov.uk')
    end

    scenario 'help step_5 page', vcr: { cassette_name: :help_step_5 } do
      title = 'Update prisoner information'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('https://moic.service.justice.gov.uk')
    end

    scenario 'help step_6 page', vcr: { cassette_name: :help_step_6 } do
      title = 'Start making allocations'

      click_link(title)

      expect(page).to have_css("h1", text: title)
      expect(page).to have_link('https://moic.service.justice.gov.uk')
      expect(page).to have_link('moic@digital.justice.gov.uk')
    end
  end
end
