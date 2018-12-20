require "rails_helper"

feature "get poms list" do
  it "shows the page", vcr: { cassette_name: :get_token } do
    signin_user

    visit "/poms"

    expect(page).to have_css(".govuk-table", count: 4)
    expect(page).to have_content("Prison Offender Managers")
    expect(page).to have_content("Prison POM")
    expect(page).to have_content("Probation POM")
  end

  it "allows viewing a POM", vcr: { cassette_name: :get_token } do
    signin_user

    visit "/poms/1"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_content("Surname, Forename")
    expect(page).to have_content("Caseload")
  end

  it "allows editing a POM", vcr: { cassette_name: :get_token } do
    signin_user

    visit "/poms/1/edit"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_css(".govuk-radios__item", count: 8)
    expect(page).to have_content("Edit profile")
    expect(page).to have_content("Working pattern")
    expect(page).to have_content("Working status")
  end
end
