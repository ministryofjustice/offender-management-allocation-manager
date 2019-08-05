require 'rails_helper'

feature 'Guidance' do
  context 'when accessing guidance page' do
    it 'provides a link to the guidance pages', vcr: { cassette_name: :guidance_link } do
      signin_user('PK000223')

      visit '/'
      expect(page).to have_link('Guidance', href: '/guidance')
    end
  end

  context 'when viewing guidance pages' do
    before do
      visit '/guidance'
    end

    scenario 'initial guidance page', vcr: { cassette_name: :guidance_initial_page } do
      guidance_links = [
          ['List everyone using the service', 'guidance_step1'],
          ['Set up access in Digital Prison Services', 'guidance_step2'],
          ['Set up POMs in NOMIS', 'guidance_step3'],
          ['Update POM profiles', 'guidance_step4'],
          ['Update prisoner information', 'guidance_step5'],
          ['Start making allocations', 'guidance_step6']
      ]

      guidance_links.each do |key, val|
        expect(page).to have_link(key, href: val)
      end

      title = 'Get started with the allocations service'

      expect(page).not_to have_link(title)
      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('https://moic.service.justice.gov.uk')

      task_links = [
          ['Task 1', 'guidance_step1'],
          ['Task 2', 'guidance_step2'],
          ['Task 3', 'guidance_step3'],
          ['Task 4', 'guidance_step4'],
          ['Task 5', 'guidance_step5'],
          ['Task 6', 'guidance_step6']
      ]

      task_links.each do |key, val|
        expect(page).to have_link(key, href: val)
      end
    end

    scenario 'guidance step_1 page', vcr: { cassette_name: :guidance_step_1 } do
      title = 'List everyone using the service'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('spreadsheet template')
      expect(page).to have_xpath("//img[contains(@src,'assets/spreadsheet_image')]")
      expect(page).to have_link('hmoic@digital.justice.gov.uk')
      expect(page).to have_link('Task 2: Set up access in Digital Prison Services', href: 'guidance_step2')
    end

    scenario 'guidance step_2 page', vcr: { cassette_name: :guidance_step_2 } do
      title = 'Set up access in Digital Prison Services'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('https://notm.service.hmpps.dsd.io/')

      images = %w[hmpps_login_image nomis_login_image admin_util_image search_staff_image staff_member_image staff_roles_image add_staff_image choose_role_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'guidance step_3 page', vcr: { cassette_name: :guidance_step_3 } do
      title = 'Set up POMs in NOMIS'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('Task 1: List everyone using the service', href: 'guidance_step1')
      expect(page).to have_link('Task 4: Update POM profiles', href: 'guidance_step4')

      images = %w[caseload2_image search_box_image action_toolbar_image caseload1_image search_box_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'guidance step_4 page', vcr: { cassette_name: :guidance_step_4 } do
      title = 'Update POM profiles'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('Task 2: Set up access in Digital Prison Services', href: 'guidance_step2')
      expect(page).to have_link('https://moic.service.justice.gov.uk')
    end

    scenario 'guidance step_5 page', vcr: { cassette_name: :guidance_step_5 } do
      title = 'Update prisoner information'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('Task 3: Set up POMs in NOMIS', href: 'guidance_step3')
      expect(page).to have_link('https://moic.service.justice.gov.uk')
      expect(page).to have_link('Home', href: '/')
    end

    scenario 'guidance step_6 page', vcr: { cassette_name: :guidance_step_6 } do
      title = 'Start making allocations'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_link('https://moic.service.justice.gov.uk')
      expect(page).to have_link('moic@digital.justice.gov.uk')
    end
  end
end
