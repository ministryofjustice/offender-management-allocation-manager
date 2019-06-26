require 'rails_helper'

RSpec.describe DeliusData, type: :model do
  it 'can insert clean data' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      tier: 'A'
    )

    expect(described_class.count).to eq(1)
    expect(TierChange.count).to eq(0)
  end

  it 'can exercise upsert' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      tier: 'A'
    )
    expect(described_class.first.tier).to eq('A')
    expect(TierChange.count).to eq(0)

    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      tier: 'B'
    )
    expect(described_class.first.tier).to eq('B')
    expect(described_class.count).to eq(1)
    expect(TierChange.count).to eq(1)
  end

  it 'can tell if a record is omicable' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      ldu_code: 'WPT123'
    )

    expect(described_class.first.omicable?).to be true
  end

  it 'can tell if a record is not omicable' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      ldu_code: 'XPT123'
    )

    expect(described_class.first.omicable?).to be false
  end

  it 'can tell if a record is CRC' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      provider_code: 'C123'
    )

    expect(described_class.first.service_provider).to eq('CRC')
  end

  it 'can tell if a record is NPS' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z',
      provider_code: 'X123'
    )

    expect(described_class.first.service_provider).to eq('NPS')
  end

  it 'can will default service provider to NPS' do
    described_class.upsert(
      crn: '1',
      noms_no: 'A1234Z'
    )

    expect(described_class.first.service_provider).to eq('NPS')
  end
end
