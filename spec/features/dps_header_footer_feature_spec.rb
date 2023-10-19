# As these tests hit the actual components API, these tests will need updating if service owners change things around,
# but it seems prudent to test the actual API responses at most once and stub them everywhere else
feature 'DPS standard header and footer:', :aggregate_failures, :skip_dps_header_footer_stubbing do
  before :each, :mock_api_error do
    stub_request(:get, "#{Rails.configuration.dps_frontend_components_api_host}/header").to_return(status: 503)
    stub_request(:get, "#{Rails.configuration.dps_frontend_components_api_host}/footer").to_return(status: 503)
  end

  scenario 'standard DPS header is used',
           vcr: { cassette_name: 'dps_header_footer/standard_header' } do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.connect-dps-external-header')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/header.css"]', visible: :all)

    # For when they add some JS
    # expect(page).to have_css('script[src="https://frontend-components-dev.hmpps.service.justice.gov.uk/......."]', visible: :all)
  end

  scenario 'fallback DPS header is used when DPS components API is not available', :mock_api_error,
           vcr: { cassette_name: 'dps_header_footer/fallback_header' } do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.govuk-header--fallback')
  end

  scenario 'standard DPS footer is used',
           vcr: { cassette_name: 'dps_header_footer/standard_footer' } do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.govuk-footer a.govuk-footer__link[href="https://sign-in-dev.hmpps.service.justice.gov.uk/auth/terms"]')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css"]', visible: :all)

    # For when they add some JS
    # expect(page).to have_css('script[src="https://frontend-components-dev.hmpps.service.justice.gov.uk/......."]', visible: :all)
  end

  scenario 'fallback DPS footer is used when DPS components API is not available', :mock_api_error,
           vcr: { cassette_name: 'dps_header_footer/fallback_footer' } do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.govuk-footer--fallback')
  end
end
