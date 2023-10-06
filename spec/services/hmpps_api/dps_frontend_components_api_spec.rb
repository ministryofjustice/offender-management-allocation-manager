RSpec.describe HmppsApi::DpsFrontendComponentsApi do
  let(:access_token) { 'TESTING_ACCESS_TOKEN' }
  let(:invalid_access_token) { 'INVALID_TESTING_ACCESS_TOKEN' }

  def stub_token(token)
    allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(double(access_token: token))
  end

  before do
    allow(Rails.configuration).to receive(:dps_frontend_components_api_host).and_return('https://example.org')

    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'x-user-token' => access_token })
      .to_return(body: '{"html": "<f>", "css": ["https://example.org/f.css"], "javascript": []}')
    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'x-user-token' => invalid_access_token })
      .to_return(status: 401)
  end

  describe '#footer' do
    it 'with valid access token, gets the footer HTML and CSS from the API' do
      stub_token(access_token)
      expect(described_class.footer)
        .to eq({ 'html' => '<f>', 'css' => ['https://example.org/f.css'], 'javascript' => [] })
    end

    it 'with invalid access token, raises 401 unauthorized' do
      stub_token(invalid_access_token)
      expect { described_class.footer }.to raise_error(Faraday::UnauthorizedError)
    end
  end
end
