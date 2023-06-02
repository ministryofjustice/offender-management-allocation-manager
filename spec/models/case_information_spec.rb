require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  let(:case_info) { create(:case_information) }

  context 'with mappa level' do
    subject { build(:case_information) }

    it 'allows 0, 1, 2, 3 and nil' do
      [0, 1, 2, 3, nil].each do |level|
        subject.mappa_level = level
        expect(subject).to be_valid
      end
    end

    it 'does not allow 4' do
      subject.mappa_level = 4
      expect(subject).not_to be_valid
    end
  end

  context 'with basic factory' do
    subject do
      build(:case_information)
    end

    it { is_expected.to be_valid }
  end

  context 'with missing tier' do
    subject do
      build(:case_information, tier: nil)
    end

    it 'gives the correct message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(tier: ['Select the prisoner’s tier'])
    end
  end

  context 'with manual flag' do
    it 'will be valid' do
      expect(build(:case_information, manual_entry: true)).to be_valid
    end
  end

  context 'without manual flag' do
    it 'will be valid' do
      expect(build(:case_information, manual_entry: false)).to be_valid
    end
  end

  context 'with null manual flag' do
    it 'wont be valid' do
      expect(build(:case_information, manual_entry: nil)).not_to be_valid
    end
  end

  context 'when probation service' do
    subject do
      build(:case_information, probation_service: nil)
    end

    it 'gives the correct validation error message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages)
        .to eq(probation_service: ["Select yes if the prisoner’s last known address was in Wales"])
    end

    it 'allows England, Wales' do
      ['England', 'Wales'].each do |service|
        subject.probation_service = service
        expect(subject).to be_valid
      end
    end
  end

  it 'ensures enhanced_handover? flag is always set based on NPS/CRC value' do
    crc_ci = FactoryBot.create :case_information, case_allocation: 'CRC'
    nps_ci = FactoryBot.create :case_information, case_allocation: 'NPS'

    aggregate_failures do
      expect(crc_ci.enhanced_handover?).to eq false
      expect(nps_ci.enhanced_handover?).to eq true
    end
  end
end
