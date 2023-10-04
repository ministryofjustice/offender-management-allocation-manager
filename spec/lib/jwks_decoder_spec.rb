RSpec.describe JwksDecoder do
  let(:encoded_token) { double :encoded_token }
  let(:decoded_token) { double :decoded_token }
  let(:mock_jwks_keys) do
    {
      'keys' => [
        {
          'kty' => 'RSA',
          'e' => 'AQAB',
          'use' => 'unused',
          'kid' => 'xxxx1',
          'alg' => 'ALGO_UNUSED',
          'n' => 'nnnnnnnn1',
        },
        {
          'kty' => 'RSA',
          'e' => 'AQAB',
          'use' => 'sig',
          'kid' => 'xxxx2',
          'alg' => 'ALGO1',
          'n' => 'nnnnnnnn2',
        },
        {
          'kty' => 'RSA',
          'e' => 'AQAB',
          'use' => 'sig',
          'kid' => 'xxxx3',
          'alg' => 'ALGO2',
          'n' => 'nnnnnnnn3',
        },
      ]
    }
  end

  describe '::decode_token' do
    subject(:result) { described_class.decode_token(encoded_token) }

    before do
      allow(HmppsApi::Oauth::Api).to receive(:fetch_jwks_keys).and_return(mock_jwks_keys)
      allow(JWT).to receive(:decode).and_return(decoded_token)

      result # evaluate it
    end

    it 'correctly decodes a JWT using API-obtained keys' do
      expect(JWT).to have_received(:decode).with(
        encoded_token,
        nil,
        true,
        algorithm: ['ALGO1', 'ALGO2'],
        jwks: JWT::JWK::Set.new({ 'keys' => mock_jwks_keys['keys'][1, 2] }).to_a,
      )
    end

    it 'returns the decoded token' do
      expect(result).to eq decoded_token
    end
  end
end
