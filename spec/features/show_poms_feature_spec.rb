require "rails_helper"

feature "get poms list" do
  it "shows the page", vcr: { cassette_name: :show_poms_feature } do
    signin_user

    visit poms_path

    expect(page).to have_css(".govuk-table", count: 4)
    expect(page).to have_content("Prison Offender Managers")
    expect(page).to have_content("Prison POM")
    expect(page).to have_content("Probation POM")

    expect(page).to have_css('.govuk-breadcrumbs')
    expect(page).to have_css('.govuk-breadcrumbs__link', count: 2)
  end

  it "allows viewing a POM", vcr: { cassette_name: :show_poms_feature } do
    signin_user

    visit "/poms/485752"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Jones, Ross")
    expect(page).to have_content("Caseload")
    expect(page).to have_css('.govuk-breadcrumbs')
    expect(page).to have_css('.govuk-breadcrumbs__link', count: 3)
  end

  it "allows editing a POM", vcr: { cassette_name: :show_poms_feature } do
    signin_user

    visit "/poms/485752/edit"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_css(".govuk-radios__item", count: 14)
    expect(page).to have_content("Edit profile")
    expect(page).to have_content("Working pattern")
    expect(page).to have_content("Status")
    expect(page).not_to have_css('.govuk-breadcrumbs')
  end
end
