# As these tests hit the actual components API, these tests will need updating if service owners change things around,
# but it seems prudent to test the actual API responses at most once and stub them everywhere else
feature 'DPS standard header and footer:', :aggregate_failures do
  scenario 'standard DPS footer is used', :skip_dps_header_footer_stubbing,
           vcr: { cassette_name: 'dps_header_footer/standard_footer' } do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.govuk-footer a.govuk-footer__link[href="https://sign-in-dev.hmpps.service.justice.gov.uk/auth/terms"]')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css"]', visible: :all)
  end

  scenario 'fallback DPS footer is used when DPS components API times out', :skip_dps_header_footer_stubbing
end
