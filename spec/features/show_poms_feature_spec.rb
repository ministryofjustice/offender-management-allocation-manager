require "rails_helper"

feature "get poms list" do
  let!(:offender_missing_sentence_case_info) { create(:case_information, nomis_offender_id: 'G1247VX') }

  it "shows the page", vcr: { cassette_name: :show_poms_feature_list } do
    signin_user

    visit prison_poms_path('LEI')

    expect(page).to have_css(".govuk-table", count: 4)
    expect(page).to have_content("Prison Offender Managers")
    expect(page).to have_content("Prison POM")
    expect(page).to have_content("Probation POM")

    expect(page).to have_css('.govuk-breadcrumbs')
    expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
  end

  it "handles missing sentence data", vcr: { cassette_name: :show_poms_feature_missing_sentence } do
    signin_user('PK000223')

    visit prison_confirm_allocation_path('LEI', offender_missing_sentence_case_info.nomis_offender_id, 485_637)
    click_button 'Complete allocation'

    visit prison_pom_path('LEI', 485_637)

    expect(page).to have_css(".pom_cases_row_0", count: 1)
    expect(page).not_to have_css(".pom_cases_row_1")
    expect(page).to have_content(offender_missing_sentence_case_info.nomis_offender_id)
  end

  it "allows viewing a POM", vcr: { cassette_name: :show_poms_feature_view } do
    signin_user

    visit "/prisons/LEI/poms/485752"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Jones, Ross")
    expect(page).to have_content("Caseload")
    expect(page).to have_css('.govuk-breadcrumbs')
    expect(page).to have_css('.govuk-breadcrumbs__link', count: 3)
  end

  it "can sort offenders allocated to a POM", vcr: { cassette_name: :show_poms_feature_view_sorting } do
    signin_user

    [['G7806VO', 754_207], ['G2911GD', 1_175_317]].each do |offender_id, booking|
      AllocationService.create_or_update(
        nomis_offender_id: offender_id,
        nomis_booking_id: booking,
        prison: 'LEI',
        allocated_at_tier: 'A',
        created_by_username: 'PK000223',
        primary_pom_nomis_id: 485_752,
        primary_pom_allocated_at: DateTime.now.utc,
        recommended_pom_type: 'probation',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      )
    end

    visit "/prisons/LEI/poms/485752"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Jones, Ross")
    expect(page).to have_content("Caseload")
    expect(page).to have_css('.govuk-breadcrumbs')
    expect(page).to have_css('.govuk-breadcrumbs__link', count: 3)
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

  it "allows editing a POM", vcr: { cassette_name: :show_poms_feature_edit } do
    signin_user

    visit "/prisons/LEI/poms/485752/edit"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_css(".govuk-radios__item", count: 14)
    expect(page).to have_content("Edit profile")
    expect(page).to have_content("Working pattern")
    expect(page).to have_content("Status")
    expect(page).not_to have_css('.govuk-breadcrumbs')
  end
end
