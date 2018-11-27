require 'rails_helper'

describe Allocation::Api do

  it 'fetches the status', vcr: { cassette_name: :status_request } do
    api = Allocation::Api.instance
    status = api.fetch_status

    expect(status["status"]).to eq "ok"
    expect(status["postgresVersion"]).to include("PostgreSQL 9.6.4")
  end
end
