require 'rails_helper'

RSpec.describe DeliusData, type: :model do
  it 'can insert clean data' do
    described_class.upsert(
      noms_no: 'A1234Z',
      tier: 'A'
    )

    expect(described_class.count).to eq(1)
    expect(TierChange.count).to eq(0)
  end

  it 'can exercise upsert' do
    described_class.upsert(
      noms_no: 'A1234Z',
      tier: 'A'
    )
    expect(described_class.first.tier).to eq('A')
    expect(TierChange.count).to eq(0)

    described_class.upsert(
      noms_no: 'A1234Z',
      tier: 'B'
    )
    expect(described_class.first.tier).to eq('B')
    expect(described_class.count).to eq(1)
    expect(TierChange.count).to eq(1)
  end
end
