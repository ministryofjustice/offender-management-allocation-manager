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
end
