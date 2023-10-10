RSpec.describe HmppsApi::DpsFrontendComponentsApi do
  let(:access_token) { 'TESTING_ACCESS_TOKEN' }
  let(:invalid_access_token) { 'INVALID_TESTING_ACCESS_TOKEN' }

  def stub_token(token)
    allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(double(access_token: token))
  end

  before do
    allow(Rails.configuration).to receive(:dps_frontend_components_api_host).and_return('https://example.org')

    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<f>", "css": ["https://example.org/f.css"], "javascript": ["f.js"]}')
    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'X-User-Token' => invalid_access_token })
      .to_return(status: 401)

    stub_request(:get, 'https://example.org/header')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<h>", "css": ["https://example.org/h.css"], "javascript": ["h.js"]}')
    stub_request(:get, 'https://example.org/header')
      .with(headers: { 'X-User-Token' => invalid_access_token })
      .to_return(status: 401)
  end

  describe '#footer' do
    it 'with valid access token, gets the footer HTML and CSS from the API' do
      stub_token(access_token)
      expect(described_class.footer)
        .to eq({ 'html' => '<f>', 'css' => ['https://example.org/f.css'], 'javascript' => ['f.js'] })
    end

    it 'with invalid access token, raises 401 unauthorized' do
      stub_token(invalid_access_token)
      expect { described_class.footer }.to raise_error(Faraday::UnauthorizedError)
    end
  end

  describe '#header' do
    it 'with valid access token, gets the header HTML and CSS from the API' do
      stub_token(access_token)
      expect(described_class.header)
        .to eq({ 'html' => '<h>', 'css' => ['https://example.org/h.css'], 'javascript' => ['h.js'] })
    end

    it 'with invalid access token, raises 401 unauthorized' do
      stub_token(invalid_access_token)
      expect { described_class.header }.to raise_error(Faraday::UnauthorizedError)
    end
  end
end
