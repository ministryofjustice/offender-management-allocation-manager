require 'rails_helper'

RSpec.describe CaseInformation, type: :model do
  let(:case_info) { create(:case_information) }

  it 'has timestamps' do
    expect(case_info.created_at).not_to be_nil
    sleep 2
    case_info.touch
    expect(case_info.updated_at).not_to eq(case_info.created_at)
  end

  describe 'associations' do
    subject { build(:case_information) }

    it { is_expected.to have_one(:responsibility).dependent(:destroy) }
    it { is_expected.to have_one(:calculated_handover_date).dependent(:destroy) }
    it { is_expected.to have_many(:early_allocations).dependent(:destroy) }
  end

  describe '#early_allocations' do
    context 'when not setup' do
      it 'is empty' do
        expect(case_info.early_allocations).to be_empty
      end
    end

    context 'with Early Allocation assessments' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }
      let!(:early_allocation2) { create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id) }

      it 'has some entries' do
        expect(case_info.early_allocations).to eq([early_allocation, early_allocation2])
      end
    end

    describe 'sort order' do
      let(:creation_dates) { [1.year.ago, 1.day.ago, 1.month.ago].map(&:to_date) }

      before do
        # Deliberately create records out of order so we can assert that we order them correctly
        # This is unlikely to happen in real life because we use numeric primary keys – but it helps for this test
        creation_dates.each do |date|
          create(:early_allocation, nomis_offender_id: case_info.nomis_offender_id, created_at: date)
        end
      end

      it 'sorts by date created (ascending)' do
        retrieved_dates = case_info.early_allocations.map(&:created_at).map(&:to_date)
        expect(retrieved_dates).to eq(creation_dates.sort)
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

    it { is_expected.to be_valid }
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
    subject {
      build(:case_information, probation_service: nil)
    }

    it 'gives the correct validation error message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).
        to eq(probation_service: ["Select yes if the prisoner’s last known address was in Wales"])
    end

    it 'allows England, Wales' do
      ['England', 'Wales'].each do |service|
        subject.probation_service = service
        expect(subject).to be_valid
      end
    end
  end
end
