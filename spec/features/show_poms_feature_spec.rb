require "rails_helper"

feature "get poms list" do
  let!(:offender_missing_sentence_case_info) { create(:case_information, nomis_offender_id: 'G7949GQ') }

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

    expect(page).to have_css(".govuk-table__row", count: 2)
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
