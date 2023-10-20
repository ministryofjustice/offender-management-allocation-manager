RSpec.describe HmppsApi::DpsFrontendComponentsApi, :skip_dps_header_footer_stubbing do
  let(:access_token) { 'TESTING_ACCESS_TOKEN' }
  let(:invalid_access_token) { 'INVALID_TESTING_ACCESS_TOKEN' }

  before do
    allow(Rails.configuration).to receive(:dps_frontend_components_api_host).and_return('https://example.org')

    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<f>", "css": ["https://example.org/f.css"], "javascript": ["f.js"]}')

    stub_request(:get, 'https://example.org/header')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<h>", "css": ["https://example.org/h.css"], "javascript": ["h.js"]}')
  end

  describe '#footer' do
    it 'with valid access token, gets the footer HTML and CSS from the API' do
      expect(described_class.footer(access_token))
        .to eq({ 'html' => '<f>', 'css' => ['https://example.org/f.css'], 'javascript' => ['f.js'] })
    end

    it 'raises exceptions for unsuccessful responses' do
      stub_request(:get, 'https://example.org/footer')
        .with(headers: { 'X-User-Token' => invalid_access_token })
        .to_return(status: 401)
      expect { described_class.footer(invalid_access_token) }.to raise_error(Faraday::UnauthorizedError)
    end
  end

  describe '#header' do
    it 'with valid access token, gets the header HTML and CSS from the API' do
      expect(described_class.header(access_token))
        .to eq({ 'html' => '<h>', 'css' => ['https://example.org/h.css'], 'javascript' => ['h.js'] })
    end

    it 'raises exceptions for unsuccessful responses' do
      stub_request(:get, 'https://example.org/header')
        .with(headers: { 'X-User-Token' => invalid_access_token })
        .to_return(status: 401)
      expect { described_class.header(invalid_access_token) }.to raise_error(Faraday::UnauthorizedError)
    end
  end
end
