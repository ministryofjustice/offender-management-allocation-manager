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
    within('section', text: 'Inactive staff') { click_on 'Anette Pomme' }
    within('.govuk-summary-list__row', text: 'Status Inactive') { click_on 'Change' }
    within('fieldset', text: 'Status') { choose 'Active' }
    click_on 'Save'

    # Then I see the POM in the active staff section
    visit prison_poms_path(prison)
    within('section', text: 'Inactive staff') { expect(page).not_to have_content('Anette Pomme') }
    within('section', text: 'Active prison officer POMs') { expect(page).to have_content('Anette Pomme') }
  end

  specify 'HOMD making POM inactive de-allocates any allocated cases' do
    # Given the POM is active
    create(:pom_detail, :active, nomis_staff_id: 1234, prison:)

    # And the POM has cases allcoated to them
    alloc1 = build(:stubbed_offender, nomis_id: 'G1234XX', first_name: 'Allocated', last_name: 'Case1')
    create(:allocation_history, nomis_offender_id: 'G1234XX', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
    alloc2 = build(:stubbed_offender, nomis_id: 'G1234YY', first_name: 'Allocated', last_name: 'Case2')
    create(:allocation_history, nomis_offender_id: 'G1234YY', primary_pom_nomis_id: 1234, primary_pom_name: 'Anette Pomme', prison: prison.code)
    stub_offenders_for_prison(prison.code, [alloc1, alloc2])

    # When I make the POM inactive
    visit prison_poms_path(prison)
    within('section', text: 'Active prison officer POMs') { click_on 'Anette Pomme' }
    within('.govuk-summary-list__row', text: 'Status Active') { click_on 'Change' }
    within('fieldset', text: 'Status') { choose 'Inactive' }
    click_on 'Save'

    # Then they appear in the inactive staff section
    visit prison_poms_path(prison)
    within('section', text: 'Inactive staff') { expect(page).to have_content('Anette Pomme') }
    within('section', text: 'Active prison officer POMs') { expect(page).not_to have_content('Anette Pomme') }

    # And the previosly allocated cases are now on the unallocated cases screen
    visit unallocated_prison_prisoners_path(prison)
    expect(page).to have_content('Case1, Allocated')
    expect(page).to have_content('Case2, Allocated')
  end
end
