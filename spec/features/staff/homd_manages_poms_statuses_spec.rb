describe 'HOMD manages POMS statuses' do
  let(:prison) { create(:prison, code: 'LEI') }

  let(:homd_user) { build(:homd) }

  let(:pom) { build(:pom, :prison_officer, staffId: 1234, firstName: 'Anette', lastName: 'Pomme') }

  before do
    stub_bank_holidays
    stub_signin_spo(homd_user)
    stub_poms(prison.code, [pom, homd_user])
    stub_offenders_for_prison(prison.code, [])
  end

  specify 'HOMD reactivates inactive POM' do
    # Given the POM is inactive
    create(:pom_detail, :inactive, nomis_staff_id: 1234, prison:)

    # When I re activate the POM
    visit prison_poms_path(prison)
    within('section', text: 'Away from work') { click_on 'Anette Pomme' }
    within('.govuk-summary-list__row', text: 'Status Away from work') { click_on 'Change' }
    within('fieldset', text: 'Select status') { choose 'Available for new cases' }
    click_on 'Save'

    # Then I see the POM in the active staff section
    visit prison_poms_path(prison)
    within('section', text: 'Away from work') { expect(page).not_to have_content('Anette Pomme') }
    within('section', text: 'Available prison POMs') { expect(page).to have_content('Anette Pomme') }
  end

  context 'when bulk_reallocation is enabled' do
    before { stub_feature_flag(:bulk_reallocation, enabled: true) }

    specify 'HOMD making POM inactive redirects to reallocation journey' do
      # Given the POM is active
      create(:pom_detail, :active, nomis_staff_id: 1234, prison:)

      # And the POM has cases allocated to them
      alloc1 = build(:stubbed_offender, nomis_id: 'G1234XX', first_name: 'Allocated', last_name: 'Case1')
      create(:allocation_history, nomis_offender_id: 'G1234XX', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
      alloc2 = build(:stubbed_offender, nomis_id: 'G1234YY', first_name: 'Allocated', last_name: 'Case2')
      create(:allocation_history, nomis_offender_id: 'G1234YY', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
      stub_offenders_for_prison(prison.code, [alloc1, alloc2])

      # When I make the POM inactive
      visit prison_poms_path(prison)
      within('section', text: 'Available prison POMs') { click_on 'Anette Pomme' }
      within('.govuk-summary-list__row', text: 'Status Available for new allocations') { click_on 'Change' }
      within('fieldset', text: 'Select status') { choose 'Away from work' }
      click_on 'Save'

      # Then I am redirected to the reallocation journey
      expect(page).to have_content('Reallocate')
    end

    context 'when selecting "No longer at prison"' do
      before do
        create(:pom_detail, :active, nomis_staff_id: 1234, prison:)
      end

      def navigate_to_confirm_delete
        visit prison_poms_path(prison)
        within('section', text: 'Available prison POMs') { click_on 'Anette Pomme' }
        within('.govuk-summary-list__row', text: 'Status Available for new allocations') { click_on 'Change' }
        within('fieldset', text: 'Select status') { choose "No longer at #{prison.name}" }
        click_on 'Save'
      end

      specify 'confirming yes with cases redirects to reallocate page' do
        alloc1 = build(:stubbed_offender, nomis_id: 'G1234XX', first_name: 'Allocated', last_name: 'Case1')
        create(:allocation_history, nomis_offender_id: 'G1234XX', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
        stub_offenders_for_prison(prison.code, [alloc1])

        navigate_to_confirm_delete

        expect(page).to have_content("Are you sure you want to remove Anette Pomme from this service?")

        choose 'Yes'
        click_on 'Continue'

        expect(page).to have_content('Reallocate')
        expect(PomDetail.find_by(nomis_staff_id: 1234).status).to eq('deleted')
      end

      specify 'confirming no returns to edit page' do
        navigate_to_confirm_delete

        choose 'No'
        click_on 'Continue'

        expect(page).to have_content('Edit profile')
        expect(PomDetail.find_by(nomis_staff_id: 1234).status).to eq('active')
      end
    end
  end

  context 'when bulk_reallocation is disabled' do
    before { stub_feature_flag(:bulk_reallocation, enabled: false) }

    specify 'edit page does not show "No longer at prison" option' do
      # Given the POM is active
      create(:pom_detail, :active, nomis_staff_id: 1234, prison:)

      # When I visit the edit page
      visit prison_poms_path(prison)
      within('section', text: 'Available prison POMs') { click_on 'Anette Pomme' }
      within('.govuk-summary-list__row', text: 'Status Available for new allocations') { click_on 'Change' }

      # Then I do not see the deleted option
      within('fieldset', text: 'Select status') do
        expect(page).to have_content('Available for new cases')
        expect(page).to have_content('Unavailable for new cases')
        expect(page).to have_content('Away from work')
        expect(page).not_to have_content("No longer at #{prison.name}")
      end
    end

    specify 'HOMD making POM inactive de-allocates any allocated cases' do
      # Given the POM is active
      create(:pom_detail, :active, nomis_staff_id: 1234, prison:)

      # And the POM has cases allocated to them
      alloc1 = build(:stubbed_offender, nomis_id: 'G1234XX', first_name: 'Allocated', last_name: 'Case1')
      create(:allocation_history, nomis_offender_id: 'G1234XX', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
      alloc2 = build(:stubbed_offender, nomis_id: 'G1234YY', first_name: 'Allocated', last_name: 'Case2')
      create(:allocation_history, nomis_offender_id: 'G1234YY', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
      stub_offenders_for_prison(prison.code, [alloc1, alloc2])

      # When I make the POM inactive
      visit prison_poms_path(prison)
      within('section', text: 'Available prison POMs') { click_on 'Anette Pomme' }
      within('.govuk-summary-list__row', text: 'Status Available for new allocations') { click_on 'Change' }
      within('fieldset', text: 'Select status') { choose 'Away from work' }
      click_on 'Save'

      # Then they appear in the away from work section
      visit prison_poms_path(prison)
      within('section', text: 'Away from work') { expect(page).to have_content('Anette Pomme') }
      within('section', text: 'Available prison POMs') { expect(page).not_to have_content('Anette Pomme') }

      # And the previously allocated cases are now on the unallocated cases screen
      visit unallocated_prison_prisoners_path(prison)
      expect(page).to have_content('Case1, Allocated')
      expect(page).to have_content('Case2, Allocated')
    end
  end
end
