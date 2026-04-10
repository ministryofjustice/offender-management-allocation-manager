# As these tests hit the actual components API, these tests will need updating if service owners change things around,
# but it seems prudent to test the actual API responses at most once and stub them everywhere else
feature 'DPS standard header and footer:', :aggregate_failures, :skip_dps_header_footer_stubbing do
  let(:api_host) { Rails.configuration.dps_frontend_components_api_host }
  let(:components_endpoint) { "#{api_host}/components" }

  let(:components_body) do
    {
      header: {
        html: '<header class="connect-dps-common-header govuk-!-display-none-print" role="banner">...</header>',
        css: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/header.css'],
        javascript: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/js/header.js']
      },
      footer: {
        html: '<footer class="connect-dps-common-footer govuk-!-display-none-print" role="contentinfo">...</footer>',
        css: ['https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css'],
        javascript: []
      },
      meta: {
        activeCaseLoad: {
          caseLoadId: 'LEI',
          description: 'Leeds (HMP)',
        },
      },
    }.to_json
  end

  let(:poms) { [build(:pom, firstName: 'Alice', position: RecommendationService::PRISON_POM, staffId: 1)] }
  let(:offenders) { build_list(:nomis_offender, 3) }

  before do
    stub_poms('LEI', poms)
    stub_offenders_for_prison('LEI', offenders)
    stub_user('MOIC_POM', 1)
  end

  before :each, :mock_api_error do
    stub_request(:get, "#{components_endpoint}?component=header&component=footer").to_return(status: 503)
  end

  before :each, :mock_api_success do
    stub_request(:get, "#{components_endpoint}?component=header&component=footer")
      .to_return(status: 200, body: components_body)
  end

  it 'uses the standard DPS header', :mock_api_success do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.connect-dps-common-header')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/header.css"]', visible: :all)
    expect(page).to have_css('script[src="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/js/header.js"]', visible: :all)
  end

  it 'uses the fallback DPS header when the DPS components API is not available', :mock_api_error do
    signin_pom_user
    visit '/'

    expect(page).to have_css('header.fallback-dps-header')
  end

  it 'uses the standard DPS footer', :mock_api_success do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.connect-dps-common-footer')
    expect(page).to have_css('link[rel=stylesheet][href="https://frontend-components-dev.hmpps.service.justice.gov.uk/assets/stylesheets/footer.css"]', visible: :all)
  end

  it 'uses the fallback DPS footer when the DPS components API is not available', :mock_api_error do
    signin_pom_user
    visit '/'

    expect(page).to have_css('footer.govuk-footer')
  end
end
