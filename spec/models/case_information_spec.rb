require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  let(:case_info) { create(:case_information) }

  it 'has timestamps' do
    expect(case_info.created_at).not_to be_nil
    sleep 2
    case_info.touch
    expect(case_info.updated_at).not_to eq(case_info.created_at)
  end

  describe '#early_allocations' do
    context 'when not setup' do
      it 'is empty' do
        expect(case_info.early_allocations).to be_empty
      end
    end

    context 'with an allocation' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }
      let!(:early_allocation2) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }

      it 'has some entries' do
        expect(case_info.early_allocations).to eq([early_allocation, early_allocation2])
      end
    end
  end

  context 'with mappa level' do
    subject { build(:case_information, nomis_offender_id: '123456') }

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

  context 'when probation service' do
    context 'with manual flag, it is required' do
      subject {
        build(:case_information, probation_service: nil)
      }

      it 'gives the correct validation error message' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to eq(probation_service: ["You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"])
      end

      it 'allows England, Wales, Scotland & Northern Ireland' do
        ['England', 'Wales', 'Scotland', 'Northern Ireland'].each do |service|
          subject.probation_service = service
          expect(subject).to be_valid
        end
      end
    end

    context 'without manual flag, it is not required' do
      it 'does not raise an error when not present' do
        expect(build(:case_information, probation_service: nil, manual_entry: false)).to be_valid
      end
    end
  end
end
