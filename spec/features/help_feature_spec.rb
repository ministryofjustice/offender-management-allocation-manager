require 'rails_helper'

feature 'Help' do
  let!(:prison) { create(:prison) }

  context 'when visiting root page' do
    it 'provides a link to the help pages', vcr: { cassette_name: 'prison_api/help_link' } do
      signin_spo_user([prison.code])

      visit '/'
      expect(page).to have_link('Help', href: '/help')
    end
  end

  context 'when visiting help page' do
    it 'has links to help options', vcr: { cassette_name: 'prison_api/help_page' } do
      visit '/help'

      help_options = [
        ['set up new users', help_step0_path],
        ['contact us', contact_us_path]
      ]

      help_options.each do |key, val|
        expect(page).to have_link(key, href: val)
      end
    end
  end

  context 'when viewing getting set up pages' do
    let(:inset_text) do
      {
        LSA: 'This step should be completed by a local system administrator after new staff members’ details have been listed.',
        SPO_HoOMU: 'This task should be completed by a head of offender management delivery (HOMD) or head of offender management services (HOMS).',
        CASE_ADMIN_0: 'This task should be completed by a head of offender management delivery (HOMD), head of offender management services (HOMS) or a case administrator after everyone who will use the service has been added to Digital Prison Services.',
        CASE_ADMIN_1: 'This task should be completed by a head of offender management delivery (HOMD), head of offender management services (HOMS) or case administrator after POMs have been added to NOMIS.',
        CASE_ADMIN_2: 'This step must be completed by a head of offender management delivery (HOMD) or head of offender management services (HOMS).'
      }
    end

    before do
      visit '/help_step0'
    end

    scenario 'getting set up pages', vcr: { cassette_name: 'prison_api/help_getting_set_up_pages' } do
      title = 'Overview'

      expect(page).not_to have_link(title)

      help_links = [
        ['List new staff members’ details', 'help_step1'],
        ['Set up access in Digital Prison Services', 'help_step2'],
        ['Set up staff in NOMIS', 'help_step3'],
        ['Update POM profiles', 'help_step4'],
        ['Update prisoner information', 'help_step5'],
        ['Start making allocations', 'help_step6']
      ]

      help_links.each do |key, val|
        expect(page).to have_link(key, href: val)
      end

      expect(page).to have_css('h1', text: title)
    end

    scenario 'help getting set up step_1 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_1' } do
      title = 'List new staff members’ details'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:SPO_HoOMU])
      expect(page).to have_link('spreadsheet template')
    end

    scenario 'help getting set up step_2 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_2' } do
      title = 'Set up access in Digital Prison Services'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:LSA])
      expect(page).to have_link('new staff members’ details have been listed', href: 'help_step1')
      expect(page).to have_link('Sign into Digital Prison Services', href: 'https://digital.prison.service.justice.gov.uk')
      expect(page).to have_link('Manage user accounts', href: 'https://manage-users.hmpps.service.justice.gov.uk/')
    end

    scenario 'help getting set up step_3 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_3' } do
      title = 'Set up staff in NOMIS'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:LSA])
      expect(page).to have_link('new staff members’ details have been listed', href: 'help_step1')
      expect(page).to have_link('next task', href: 'help_step4')

      images = %w[search_box_image caseload2_image caseload1_image]

      images.each do |image|
        expect(page).to have_xpath("//img[contains(@src,'assets/#{image}')]")
      end
    end

    scenario 'help getting set up step_4 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_4' } do
      title = 'Update POM profiles'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:CASE_ADMIN_0])
      expect(page).to have_link('everyone who will use the service has been added to Digital Prison Services', href: 'help_step2')
      expect(page).to have_link('Manage your staff', href: 'prisons/LEI/poms')
    end

    scenario 'help getting set up step_5 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_5' } do
      title = 'Update prisoner information'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:CASE_ADMIN_1])
      expect(page).to have_link('POMs have been added to NOMIS', href: 'help_step3')
      expect(page).to have_link('Add missing details', href: 'prisons/LEI/prisoners/missing_information')
    end

    scenario 'help getting set up step_6 page', vcr: { cassette_name: 'prison_api/help_getting_set_up_step_6' } do
      title = 'Start making allocations'

      click_link(title)

      expect(page).to have_css('h1', text: title)
      expect(page).to have_css('.govuk-inset-text', text: inset_text[:SHRUG])
      expect(page).to have_link('Make new allocations', href: 'prisons/LEI/prisoners/unallocated')
    end
  end
end
