require './app/services/allocation/api.rb'

describe Allocation::Api do
  it 'fetches an auth token', vcr: { cassette_name: :token_request } do
    api = Allocation::Api.instance
    token = api.fetch_auth_token

    expect(token).to be_kind_of(Nomis::Token)
    expect(token.type).to eq('bearer')
    expect(token.expiry).to be(1199)
    expect(token.access_token).to be_kind_of(String)
  end

  it 'fetches the status', vcr: { cassette_name: :status_request, record: :all } do
    api = Allocation::Api.instance
    status = api.fetch_status

    expect(status).to eq "something"
  end
end
