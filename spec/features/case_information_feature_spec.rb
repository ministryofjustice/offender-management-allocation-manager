# frozen_string_literal: true

require 'rails_helper'

feature 'case information feature' do
  context 'when doing an allocate and save' do
    let(:prison) { create(:prison) }
    let(:offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:spo) { build(:pom) }

    before do
      stub_signin_spo(spo, [prison.code])
      stub_auth_token
      stub_offenders_for_prison(prison.code, [offender])
      stub_poms(prison.code, [spo])
    end

    context 'when add missing details the first time (create journey)' do
      before do
        visit new_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        find('label[for=case-information-probation-service-england-field]').click
        find('label[for=case-information-case-allocation-nps-field]').click
        find('label[for=case-information-tier-a-field]').click
      end

      it 'allows spo to save case information and then returns to add missing info page' do
        click_button 'Save'
        expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code), ignore_query: true)
      end

      it 'allows spo to redirect to allocation page after adding missing information' do
        expect {
          click_button 'Save and allocate'
        }.to change(CaseInformation, :count).by 1

        expect(page).to have_current_path prison_prisoner_staff_index_path(prison.code, offender.fetch(:prisonerNumber))
      end
    end

    context 'when updating missing information (edit journey)' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
      end

      it 'no longer displays the save and allocate button', :js do
        visit edit_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        expect(page).to have_no_button('Save and allocate')
      end
    end
  end

  context 'with vcr' do
    let(:staff_id) { 485_833 }
    let(:poms) { [build(:pom, staffId: staff_id)] }

    before do
      signin_spo_user
    end

    it 'adds tiering and case information for a prisoner', :js, vcr: { cassette_name: 'prison_api/case_information_feature' } do
      # # This NOMIS id needs to appear on the first page of 'missing information'
      nomis_offender_id = 'G2911GD'

      visit missing_information_prison_prisoners_path('LEI')

      expect(page).to have_content('Add missing details')
      within "#edit_#{nomis_offender_id}" do
        click_link 'Add missing details'
      end

      find('label[for=case-information-probation-service-england-field]').click
      find('label[for=case-information-case-allocation-nps-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Save'

      expect(CaseInformation.count).to eq(1)
      expect(CaseInformation.first.nomis_offender_id).to eq(nomis_offender_id)
      expect(CaseInformation.first.tier).to eq('A')
      expect(CaseInformation.first.case_allocation).to eq('NPS')
      wait_for { current_url.include?(missing_information_prison_prisoners_path('LEI')) }
      expect(page).to have_css('.offender_row_0', count: 1)
    end

    it "clicking back link after viewing prisoner's case information, returns back the same paginated page",
       vcr: { cassette_name: 'prison_api/case_information_back_link' }, js: true do
      visit missing_information_prison_prisoners_path('LEI', page: 3)
      expect(current_page_number).to eq(3)
      within ".govuk-table tr:first-child td:nth-child(3)" do
        click_link 'Add missing details'
      end
      expect(page).to have_selector('h1', text: 'Case information')
      click_link 'Back'
      find('#awaiting-information')
      expect(page).to have_selector('h1', text: 'Add missing details')
      expect(current_page_number).to eq(3)
    end

    it 'complains if allocation data is missing', vcr: { cassette_name: 'prison_api/case_information_missing_case_feature' } do
      nomis_offender_id = 'G1821VA'

      visit new_prison_case_information_path('LEI', nomis_offender_id)
      expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

      find('label[for=case-information-tier-a-field]').click
      click_button 'Save'

      expect(CaseInformation.count).to eq(0)
      expect(page).to have_content("Select the service provider for this case")
      expect(page).to have_content("Select yes if the prisoner’s last known address was in Wales")
    end

    it 'complains if all data is missing', vcr: { cassette_name: 'prison_api/case_information_missing_all_feature' } do
      nomis_offender_id = 'G1821VA'

      visit new_prison_case_information_path('LEI', nomis_offender_id)
      expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

      click_button 'Save'

      expect(CaseInformation.count).to eq(0)
      expect(page).to have_content("Select the service provider for this case")
      expect(page).to have_content("Select the prisoner’s tier")
      expect(page).to have_content("Select yes if the prisoner’s last known address was in Wales")
    end

    it 'complains if tier data is missing', vcr: { cassette_name: 'prison_api/case_information_missing_tier_feature' } do
      nomis_offender_id = 'G1821VA'

      visit new_prison_case_information_path('LEI', nomis_offender_id)
      expect(page).to have_current_path new_prison_case_information_path('LEI', nomis_offender_id)

      find('label[for=case-information-case-allocation-nps-field]').click
      click_button 'Save'

      expect(CaseInformation.count).to eq(0)
      expect(page).to have_content("Select the prisoner’s tier")
    end

    it 'returns to previously paginated page after saving',
       vcr: { cassette_name: 'prison_api/case_information_return_to_previously_paginated_page' } do
      visit missing_information_prison_prisoners_path('LEI', sort: "last_name desc", page: 3)
      expect(current_page_number).to eq(3)

      within ".govuk-table tr:first-child td:nth-child(3)" do
        click_link 'Add missing details'
      end
      expect(page).to have_selector('h1', text: 'Case information')

      find('label[for=case-information-probation-service-england-field]').click
      find('label[for=case-information-case-allocation-nps-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Save'

      expect(current_url).to have_content(missing_information_prison_prisoners_path('LEI') + "?page=3&sort=last_name+desc")
      expect(current_page_number).to eq(3)
    end
  end
end
