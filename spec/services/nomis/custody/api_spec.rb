require 'rails_helper'

describe Nomis::Custody::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches the staff\'s details' do
    allow_any_instance_of(Nomis::Custody::Client).to receive(:get).and_return(
      activenomiscaseload: 'LEI'
    )

    username = 'Fred'

    response = described_class.fetch_nomis_staff_details(username)

    expect(response[:activenomiscaseload]).to eq "LEI"
  end
end
