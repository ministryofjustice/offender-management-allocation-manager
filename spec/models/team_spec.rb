require 'rails_helper'

RSpec.describe Team, type: :model do
  it {
    expect(subject).to validate_presence_of :name
  }

  it 'expects one of shadow code and code to be present' do
    expect(build(:team, code: nil, shadow_code: nil)).not_to be_valid
    expect(build(:team, code: 'N123', shadow_code: nil)).to be_valid
    expect(build(:team, code: nil, shadow_code: 'N123')).to be_valid
  end

  describe '#with_email_address' do
    before do
      create(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))
      create(:team, local_divisional_unit: build(:local_divisional_unit))
      create(:team, local_divisional_unit: nil)
    end

    it 'finds just one team' do
      expect(described_class.with_email_address.count).to eq(1)
    end
  end

  describe '#with_email_address' do
    before do
      create(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))
      create(:team, local_divisional_unit: build(:local_divisional_unit))
      create(:team, local_divisional_unit: nil)
    end

    it 'finds just one team' do
      expect(described_class.with_email_address.count).to eq(1)
    end
  end

  context 'when NPS' do
    before do
      create(:team, :nps)
    end

    let(:oldteam) { described_class.first }

    context 'with a duplicate team code' do
      let(:team) { build(:team, :nps, code: oldteam.code) }

      it 'does not allow duplicate team codes' do
        expect(team).not_to be_valid
        expect(team.errors.count).to eq(1)
        expect(team.errors.first).to eq([:code, "has already been taken"])
      end
    end

    context 'with a duplicate shadow code' do
      let(:team) { build(:team, :nps, shadow_code: oldteam.shadow_code) }

      it 'does not allow duplicate team codes' do
        expect(team).not_to be_valid
        expect(team.errors.count).to eq(1)
        expect(team.errors.first).to eq([:shadow_code, "has already been taken"])
      end
    end

    context 'with a duplicate team name' do
      let(:team) { build(:team, :nps, name: oldteam.name) }

      it 'is not valid' do
        expect(team).not_to be_valid
        expect(team.errors.to_a).to eq(["Name has already been taken"])
      end
    end
  end

  context 'when CRC' do
    before do
      create(:team, :crc)
    end

    let(:oldteam) { described_class.first }

    context 'with a duplicate team code' do
      let(:team) { build(:team, :crc, code: oldteam.code) }

      it 'allows duplicate team codes' do
        expect(team).to be_valid
      end
    end

    context 'with a duplicate shadow code' do
      let(:team) { build(:team, :crc, shadow_code: oldteam.shadow_code) }

      it 'is valid' do
        expect(team).to be_valid
      end
    end

    context 'with a duplicate team name' do
      let(:team) { build(:team, :crc, name: oldteam.name) }

      it 'is valid' do
        expect(team).to be_valid
      end
    end
  end
end
