require 'rails_helper'

describe HmppsApi::Oauth::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches an auth token', vcr: { cassette_name: 'prison_api/nomis_oauth_api_auth_token_spec' } do
    token = described_class.fetch_new_auth_token

    expect(token).to be_kind_of(HmppsApi::Oauth::Token)
  end

  describe 'JWKS keys' do
    it 'are fetched correctly', vcr: { cassette_name: 'prison_api/nomis_oauth_jwks_keys_spec' }, aggregate_failures: true do
      payload = described_class.fetch_jwks_keys
      expect(payload.keys).to eq ['keys']
      keys = payload.fetch('keys')
      expect(keys.size).to be >= 1
      key = keys.first
      expect(key.keys).to include('n', 'e', 'alg', 'kty', 'use')
    end
  end
end
