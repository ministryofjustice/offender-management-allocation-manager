# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Offender, type: :model do
  let(:offender) { create(:offender) }

  describe '#nomis_offender_id' do
    subject { build(:offender) }

    # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters>
    let(:valid_ids) { %w[A0000AA Z5432HD A4567CD] }

    let(:invalid_ids) {
      [
        'A 1234 AA', # no spaces allowed
        'E123456', # this is a nDelius CRN, not a NOMIS ID
        'A0000aA', # must be all uppercase
        '', # cannot be empty
        nil, # cannot be nil
        '1234567',
        'ABCDEFG',
      ]
    }

    it 'requires a valid NOMIS offender ID' do
      valid_ids.each do |id|
        subject.nomis_offender_id = id
        expect(subject).to be_valid
      end

      invalid_ids.each do |id|
        subject.nomis_offender_id = id
        expect(subject).not_to be_valid
      end
    end
  end


  describe '#early_allocations' do
    it { is_expected.to have_many(:early_allocations).dependent(:destroy) }

    context 'when not setup' do
      it 'is empty' do
        expect(offender.early_allocations).to be_empty
      end
    end

    context 'with Early Allocation assessments' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: offender.nomis_offender_id) }
      let!(:early_allocation2) { create(:early_allocation, nomis_offender_id: offender.nomis_offender_id) }

      it 'has some entries' do
        expect(offender.early_allocations).to eq([early_allocation, early_allocation2])
      end
    end

    describe 'sort order' do
      let(:creation_dates) { [1.year.ago, 1.day.ago, 1.month.ago].map(&:to_date) }

      before do
        # Deliberately create records out of order so we can assert that we order them correctly
        # This is unlikely to happen in real life because we use numeric primary keys – but it helps for this test
        creation_dates.each do |date|
          create(:early_allocation, nomis_offender_id: offender.nomis_offender_id, created_at: date)
        end
      end

      it 'sorts by date created (ascending)' do
        retrieved_dates = offender.early_allocations.map(&:created_at).map(&:to_date)
        expect(retrieved_dates).to eq(creation_dates.sort)
      end
    end
  end
end
