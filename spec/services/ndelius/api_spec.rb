require 'rails_helper'

describe Ndelius::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'gets an NDelius record' do
    nomis_id = 'A1234BA'
    expect(described_class.get_record(nomis_id)).
      to be_kind_of(Ndelius::FakeRecord)
  end
end
