require './app/services/allocation/api.rb'

describe Allocation::Api, vcr: { cassette_name: :token_request } do
  it 'fetches an auth token' do
    api = Allocation::Api.instance
    token = api.fetch_auth_token

    expect(token).to be_kind_of(Nomis::Token)
    expect(token.type).to eq('bearer')
    expect(token.expiry).to be(1199)
    expect(token.access_token).to be_kind_of(String)
  end
end
