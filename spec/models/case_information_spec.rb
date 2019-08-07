require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  context 'with mappa level' do
    subject { build(:case_information, nomis_offender_id: '123456') }

    it 'allows 1, 2, 3 and nil' do
      [1, 2, 3, nil].each do |level|
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
    subject {
      build(:case_information)
    }

    it { should be_valid }
  end

  context 'with missing tier' do
    subject {
      build(:case_information, tier: nil)
    }

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
end
