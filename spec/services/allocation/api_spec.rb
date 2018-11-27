require 'rails_helper'

describe Allocation::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches the status', vcr: { cassette_name: :api_status_request } do
    api = described_class.instance
    status = api.fetch_status

    expect(status["status"]).to eq "ok"
    expect(status["postgresVersion"]).to include("PostgreSQL 10.3")
  end
end
