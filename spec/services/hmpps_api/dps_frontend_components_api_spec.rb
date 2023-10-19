RSpec.describe HmppsApi::DpsFrontendComponentsApi, :skip_dps_header_footer_stubbing do
  let(:access_token) { 'TESTING_ACCESS_TOKEN' }
  let(:invalid_access_token) { 'INVALID_TESTING_ACCESS_TOKEN' }

  def stub_token(token)
    allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(double(access_token: token))
  end

  before do
    allow(Rails.configuration).to receive(:dps_frontend_components_api_host).and_return('https://example.org')
    stub_token(access_token)

    stub_request(:get, 'https://example.org/footer')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<f>", "css": ["https://example.org/f.css"], "javascript": ["f.js"]}')

    stub_request(:get, 'https://example.org/header')
      .with(headers: { 'X-User-Token' => access_token })
      .to_return(body: '{"html": "<h>", "css": ["https://example.org/h.css"], "javascript": ["h.js"]}')
  end

  describe '#footer' do
    it 'with valid access token, gets the footer HTML and CSS from the API' do
      expect(described_class.footer)
        .to eq({ 'html' => '<f>', 'css' => ['https://example.org/f.css'], 'javascript' => ['f.js'] })
    end

    it 'with invalid access token, raises 401 unauthorized even if a block is given' do
      stub_token(invalid_access_token)
      stub_request(:get, 'https://example.org/footer')
        .with(headers: { 'X-User-Token' => invalid_access_token })
        .to_return(status: 401)
      expect { described_class.footer { 'unused block' } }.to raise_error(Faraday::UnauthorizedError)
    end

    it 'yield the block if API has problems', :aggregate_failures do
      stub_request(:get, 'https://example.org/footer').with(headers: { 'X-User-Token' => access_token })
        .to_return(status: 503)
      expect { |blk| described_class.footer(&blk) }.to yield_with_no_args

      stub_request(:get, 'https://example.org/footer').with(headers: { 'X-User-Token' => access_token })
                                                      .to_return(status: 404)
      expect { |blk| described_class.footer(&blk) }.to yield_with_no_args
    end
  end

  describe '#header' do
    it 'with valid access token, gets the header HTML and CSS from the API' do
      expect(described_class.header)
        .to eq({ 'html' => '<h>', 'css' => ['https://example.org/h.css'], 'javascript' => ['h.js'] })
    end

    it 'with invalid access token, raises 401 unauthorized even if a block is given' do
      stub_token(invalid_access_token)
      stub_request(:get, 'https://example.org/header')
        .with(headers: { 'X-User-Token' => invalid_access_token })
        .to_return(status: 401)
      expect { described_class.header { 'unused block' } }.to raise_error(Faraday::UnauthorizedError)
    end

    it 'yield the block if API has problems', :aggregate_failures do
      stub_request(:get, 'https://example.org/header').with(headers: { 'X-User-Token' => access_token })
                                                      .to_return(status: 503)
      expect { |blk| described_class.header(&blk) }.to yield_with_no_args

      stub_request(:get, 'https://example.org/header').with(headers: { 'X-User-Token' => access_token })
                                                      .to_return(status: 404)
      expect { |blk| described_class.header(&blk) }.to yield_with_no_args
    end
  end
end
