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
      status: 'ok',
      postgresVersion: 'PostgreSQL 10.3'
    )

    response = described_class.status

    expect(response[:status]).to eq "ok"
    expect(response[:postgresVersion]).to include("PostgreSQL 10.3")
  end

  it 'gets a list allocation records for a POMs' do
    first_staff_id = '1234567'
    second_staff_id = '1234568'
    third_staff_id = '1234569'

    records = described_class.get_allocation_data([
      first_staff_id,
      second_staff_id,
      third_staff_id
    ])

    expect(records.length).to be(3)
    expect(records.values).to all(be_an Allocation::FakeAllocationRecord)
  end
end
