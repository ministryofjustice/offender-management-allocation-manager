require 'rails_helper'

describe Nomis::Oauth::Api do
  it 'fetches an auth token', vcr: { cassette_name: :token_request } do
    api = Nomis::Oauth::Api.instance
    token = api.fetch_auth_token

    expect(token).to be_kind_of(Nomis::Oauth::Token)
    expect(token.type).to eq('bearer')
    expect(token.expiry).to be(1199)
    expect(token.encrypted_token).to be_kind_of(String)
  end
end
