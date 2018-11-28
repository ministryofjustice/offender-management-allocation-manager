require 'rails_helper'

describe Allocation::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches the api status' do
    allow_any_instance_of(Allocation::Client).to receive(:get).and_return(
      {
        status: 'ok',
        postgresVersion: 'PostgreSQL 10.3'
      }
    )

    response = described_class.get_status

    expect(response[:status]).to eq "ok"
    expect(response[:postgresVersion]).to include("PostgreSQL 10.3")
  end
end
