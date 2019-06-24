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

# t.string "crn"
# t.string "pnc_no"
# t.string "noms_no"
# t.string "fullname"
# t.string "tier"
# t.string "roh_cds"
# t.string "offender_manager"
# t.string "org_private_ind"
# t.string "org"
# t.string "provider"
# t.string "provider_code"
# t.string "ldu"
# t.string "ldu_code"
# t.string "team"
# t.string "team_code"
# t.string "mappa"
# t.string "mappa_levels"
