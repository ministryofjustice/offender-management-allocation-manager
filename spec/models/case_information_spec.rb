require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  let(:subject) { build(:case_information, nomis_offender_id: '123456') }

  context 'with mappa level' do
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

  context 'with manual flag' do
    it 'can be true' do
      expect(build(:case_information, manual_entry: true)).to be_valid
    end
  end

  context 'without manual flag' do
    it 'can be false' do
      expect(build(:case_information, manual_entry: false)).to be_valid
    end
  end

  context 'with null manual flag' do
    it 'cannot be nil' do
      expect(build(:case_information, manual_entry: nil)).not_to be_valid
    end
  end
end
