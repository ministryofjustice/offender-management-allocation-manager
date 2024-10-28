# As these tests hit the actual components API, these tests will need updating if service owners change things around,
# but it seems prudent to test the actual API responses at most once and stub them everywhere else
feature 'DPS standard header and footer:', :aggregate_failures, :skip_dps_header_footer_stubbing do
  let(:api_host) { Rails.configuration.dps_frontend_components_api_host }
  let(:header_endpoint) { "#{api_host}/header" }
  let(:footer_endpoint) { "#{api_host}/footer" }

  let(:header_body) do
    {
      html: '<header class="connect-dps-common-header govuk-!-display-none-print" role="banner">...</header>',
      css: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/header.css'],
      javascript: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/js/header.js']
    }.to_json
  end

  let(:footer_body) do
    {
      html: '<footer class="connect-dps-common-footer govuk-!-display-none-print" role="contentinfo">...</footer>',
      css: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css'],
      javascript: []
    }.to_json
  end

  let(:poms) { [build(:pom, firstName: 'Alice', position: RecommendationService::PRISON_POM, staffId: 1)] }
  let(:offenders) { build_list(:nomis_offender, 3) }

  before do
    stub_poms('LEI', poms)
    stub_offenders_for_prison('LEI', offenders)

    stub_request(:get, "#{Rails.configuration.prison_api_host}/api/users/MOIC_POM")
      .to_return(body: { 'staffId': 1 }.to_json)
  end

  before :each, :mock_api_error do
    stub_request(:get, header_endpoint).to_return(status: 503)
    stub_request(:get, footer_endpoint).to_return(status: 503)
  end

  before :each, :mock_api_success do
    stub_request(:get, header_endpoint).to_return(status: 200, body: header_body)
    stub_request(:get, footer_endpoint).to_return(status: 200, body: footer_body)
  end

  scenario 'standard DPS header is used', :mock_api_success do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.connect-dps-common-header')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/header.css"]', visible: :all)
    expect(page).to have_css('script[src="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/js/header.js"]', visible: :all)
  end

  scenario 'fallback DPS header is used when DPS components API is not available', :mock_api_error do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.govuk-header--fallback')
  end

  scenario 'standard DPS footer is used', :mock_api_success do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.connect-dps-common-footer')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css"]', visible: :all)
  end

  scenario 'fallback DPS footer is used when DPS components API is not available', :mock_api_error do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.govuk-footer--fallback')
  end
end
