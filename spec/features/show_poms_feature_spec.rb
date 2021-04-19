require "rails_helper"

feature "get poms list" do
  let!(:offender_missing_sentence_case_info) { create(:case_information, nomis_offender_id: 'G1247VX') }

  before do
    signin_spo_user
  end

  it "shows the page", vcr: { cassette_name: 'prison_api/show_poms_feature_list' } do
    visit prison_poms_path('LEI')

    # shows 3 tabs - probation, prison and inactive
    expect(page).to have_css(".govuk-tabs__list-item", count: 3)
    expect(page).to have_content("Active Probation officer POMs")
    expect(page).to have_content("Active Prison officer POMs")
    expect(page).to have_content("Inactive staff")
  end

  it "handles missing sentence data", vcr: { cassette_name: 'prison_api/show_poms_feature_missing_sentence' } do
    visit prison_confirm_allocation_path('LEI', offender_missing_sentence_case_info.nomis_offender_id, 485_926)
    click_button 'Complete allocation'

    visit prison_pom_path('LEI', 485_926)

    expect(page).to have_css(".pom_cases_row_0", count: 1)
    expect(page).not_to have_css(".pom_cases_row_1")
    expect(page).to have_content(offender_missing_sentence_case_info.nomis_offender_id)
  end

  it "allows viewing a POM", vcr: { cassette_name: 'prison_api/show_poms_feature_view' } do
    visit "/prisons/LEI/poms/485926"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Pom, Moic")
    expect(page).to have_content("Caseload")
  end

  it "can sort offenders allocated to a POM", vcr: { cassette_name: 'prison_api/show_poms_feature_view_sorting' } do
    [['G7806VO', 754_207], ['G2911GD', 1_175_317]].each do |offender_id, _booking|
      create(:case_information, nomis_offender_id: offender_id)
      AllocationService.create_or_update(
        nomis_offender_id: offender_id,
        prison: 'LEI',
        allocated_at_tier: 'A',
        created_by_username: 'MOIC_POM',
        primary_pom_nomis_id: 485_926,
        primary_pom_allocated_at: DateTime.now.utc,
        recommended_pom_type: 'prison',
        event: Allocation::ALLOCATE_PRIMARY_POM,
        event_trigger: Allocation::USER
      )
    end

    visit "/prisons/LEI/poms/485926"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Pom, Moic")
    expect(page).to have_content("Caseload")
    expect(page).to have_css('.sort-arrow', count: 1)

    check_for_order = lambda { |names|
      row0 = page.find(:css, '.pom_cases_row_0')
      row1 = page.find(:css, '.pom_cases_row_1')

      within row0 do
        expect(page).to have_content(names[0])
      end

      within row1 do
        expect(page).to have_content(names[1])
      end
    }

    check_for_order.call(['Abdoria, Ongmetain', 'Ahmonis, Imanjah'])
    click_link('Prisoner name')
    check_for_order.call(['Ahmonis, Imanjah', 'Abdoria, Ongmetain'])
  end

  it "allows editing a POM", vcr: { cassette_name: 'prison_api/show_poms_feature_edit' } do
    visit "/prisons/LEI/poms/485926/edit"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_css(".govuk-radios__item", count: 14)
    expect(page).to have_content("Edit profile")
    expect(page).to have_content("Working pattern")
    expect(page).to have_content("Status")
  end
end
