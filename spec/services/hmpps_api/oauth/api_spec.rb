require 'rails_helper'

describe HmppsApi::Oauth::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches an auth token', vcr: { cassette_name: :nomis_oauth_api_auth_token_spec } do
    token = described_class.fetch_new_auth_token

    expect(token).to be_kind_of(HmppsApi::Oauth::Token)
  end
end
