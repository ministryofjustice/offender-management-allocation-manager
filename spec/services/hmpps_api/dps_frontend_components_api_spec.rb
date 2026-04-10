RSpec.describe HmppsApi::DpsFrontendComponentsApi, :skip_dps_header_footer_stubbing do
  let(:access_token) { 'TESTING_ACCESS_TOKEN' }
  let(:invalid_access_token) { 'INVALID_TESTING_ACCESS_TOKEN' }
  let(:components_response) do
    {
      header: { html: '<h>', css: ['https://example.org/h.css'], javascript: ['h.js'] },
      footer: { html: '<f>', css: ['https://example.org/f.css'], javascript: ['f.js'] },
      meta: {
        activeCaseLoad: {
          caseLoadId: 'LEI',
          description: 'Leeds (HMP)',
        },
      },
    }.to_json
  end

  before do
    allow(Rails.configuration).to receive(:dps_frontend_components_api_host).and_return('https://example.org')
  end

  describe '#components' do
    before do
      stub_request(:get, 'https://example.org/components?component=header&component=footer')
        .with(headers: { 'X-User-Token' => access_token })
        .to_return(body: components_response)
    end

    it 'gets the requested DPS components and metadata from the API' do
      expect(described_class.components(access_token)).to eq(
        {
          'header' => { 'html' => '<h>', 'css' => ['https://example.org/h.css'], 'javascript' => ['h.js'] },
          'footer' => { 'html' => '<f>', 'css' => ['https://example.org/f.css'], 'javascript' => ['f.js'] },
          'meta' => {
            'activeCaseLoad' => {
              'caseLoadId' => 'LEI',
              'description' => 'Leeds (HMP)',
            },
          },
        }
      )
    end

    it 'raises exceptions for unsuccessful responses' do
      stub_request(:get, 'https://example.org/components?component=header&component=footer')
        .with(headers: { 'X-User-Token' => invalid_access_token })
        .to_return(status: 401)
      expect { described_class.components(invalid_access_token) }.to raise_error(Faraday::UnauthorizedError)
    end
  end
end
