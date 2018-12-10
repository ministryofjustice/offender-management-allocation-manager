require 'rails_helper'

describe Nomis::Custody::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  around do |ex|
    travel_to Date.new(2018, 11, 10, 13) do
      ex.run
    end
  end

  it "fetches the staff's details",
    vcr: { cassette_name: :fetch_nomis_staff_details } do
    username = 'PK000223'

    response = described_class.fetch_nomis_staff_details(username)

    expect(response['activeNomisCaseload']).to eq "LEI"
  end

  it 'fetches prisoner information for a particular prison',
    vcr: { cassette_name: :get_prisoners } do
    prison = 'LEI'

    response = described_class.get_offenders(prison)

    expect(response.count).to eq(10)
  end
end
