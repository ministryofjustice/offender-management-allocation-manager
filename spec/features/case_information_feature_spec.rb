# frozen_string_literal: true

require 'rails_helper'

feature 'case information feature' do
  context 'when doing an allocate and save' do
    let(:prison) { build(:prison) }
    let(:offender) { build(:nomis_offender, agencyId: prison.code) }
    let(:spo) { build(:pom) }

    before do
      stub_signin_spo(spo, [prison.code])
      stub_auth_token
      stub_offenders_for_prison(prison.code, [offender])
      stub_poms(prison.code, [spo])
    end

    context 'when add missing information the first time (create journey)' do
      before do
        visit new_prison_case_information_path(prison.code, offender.fetch(:offenderNo))
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

        expect(page).to have_current_path prison_prisoner_staff_index_path(prison.code, offender.fetch(:offenderNo))
      end
    end

    context 'when updating missing information (edit journey)' do
      before do
        create(:case_information, nomis_offender_id: offender.fetch(:offenderNo))
      end

      it 'no longer displays the save and allocate button', :js do
        visit edit_prison_case_information_path(prison.code, offender.fetch(:offenderNo))
        expect(page).to have_no_button('Save and allocate')
      end
    end
  end

  context 'with vcr' do
    before do
      signin_spo_user
    end

    it 'adds tiering and case information for a prisoner', :js, vcr: { cassette_name: 'prison_api/case_information_feature' } do
      # # This NOMIS id needs to appear on the first page of 'missing information'
      nomis_offender_id = 'G2911GD'

      visit missing_information_prison_prisoners_path('LEI')

      expect(page).to have_content('Add missing information')
      within "#edit_#{nomis_offender_id}" do
        click_link 'Edit'
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

      within ".govuk-table tr:first-child td:nth-child(5)" do
        click_link 'Edit'
      end
      expect(page).to have_selector('h1', text: 'Case information')
      click_link 'Back'
      find('#awaiting-information')
      expect(page).to have_selector('h1', text: 'Add missing information')
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

    it 'allows editing case information for a prisoner', vcr: { cassette_name: 'prison_api/case_information_editing_feature' } do
      nomis_offender_id = 'G1821VA'

      visit new_prison_case_information_path('LEI', nomis_offender_id)
      find('label[for=case-information-probation-service-england-field]').click
      find('label[for=case-information-case-allocation-nps-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Save'

      visit edit_prison_case_information_path('LEI', nomis_offender_id)

      expect(page).to have_content('Case information')
      expect(page).to have_content('G1821VA')
      find('label[for=case-information-probation-service-england-field]').click
      find('label[for=case-information-case-allocation-crc-field]').click
      click_button 'Update'

      expect(CaseInformation.count).to eq(1)
      expect(CaseInformation.first.nomis_offender_id).to eq(nomis_offender_id)
      expect(CaseInformation.first.tier).to eq('A')
      expect(CaseInformation.first.case_allocation).to eq('CRC')

      expect(page).to have_current_path prison_prisoner_staff_index_path('LEI', nomis_offender_id)
      expect(page).to have_content('CRC')
    end

    it 'returns to previously paginated page after saving',
       vcr: { cassette_name: 'prison_api/case_information_return_to_previously_paginated_page' } do
      visit missing_information_prison_prisoners_path('LEI', sort: "last_name desc", page: 3)

      within ".govuk-table tr:first-child td:nth-child(5)" do
        click_link 'Edit'
      end
      expect(page).to have_selector('h1', text: 'Case information')

      find('label[for=case-information-probation-service-england-field]').click
      find('label[for=case-information-case-allocation-nps-field]').click
      find('label[for=case-information-tier-a-field]').click
      click_button 'Save'

      expect(current_url).to have_content(missing_information_prison_prisoners_path('LEI') + "?page=3&sort=last_name+desc")
    end

    it 'does not show update link on view only case info',
       vcr: { cassette_name: 'prison_api/case_information_no_update_feature' } do
      # When auto-delius is on there should be no update link to modify the case info
      # as it may not exist yet. We run this test with an indeterminate and a determine offender

      # Indeterminate offender
      nomis_offender_id = 'G0806GQ'
      visit prison_case_information_path('LEI', nomis_offender_id)
      expect(page).not_to have_css('#edit-prd-link')

      # Determinate offender
      nomis_offender_id = 'G2911GD'
      visit prison_case_information_path('LEI', nomis_offender_id)
      expect(page).not_to have_css('#edit-prd-link')
    end
  end
end
