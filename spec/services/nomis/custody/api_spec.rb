require 'rails_helper'

describe Nomis::Custody::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it "gets staff details",
    vcr: { cassette_name: :get_nomis_staff_details } do
    username = 'PK000223'

    response = described_class.fetch_nomis_staff_details(username)

    expect(response.data).to be_kind_of(Nomis::StaffDetails)
    expect(response.data.active_nomis_caseload).to eq('LEI')
  end
end
