require 'rails_helper'

describe Nomis::Elite2::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it "can get a list of offenders", vcr: { cassette_name: :get_elite2_offender_list }  do
    response = described_class.get_offender_list('LEI')
    expect(response).not_to be_nil
    expect(response.data).to be_instance_of(Array)
    expect(response.data.first).to be_instance_of(Nomis::OffenderShort)
  end
end
