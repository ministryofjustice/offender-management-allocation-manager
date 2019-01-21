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

  it 'gets a batch of NDelius records' do
    first_nomis_id = 'A1234BA'
    second_nomis_id = 'A1234BB'
    third_nomis_id = 'A1234BC'

    records = described_class.get_records([first_nomis_id, second_nomis_id, third_nomis_id])

    expect(records.length).to be(3)
    expect(records.values).to all(be_an(Ndelius::FakeRecord))
  end
end
