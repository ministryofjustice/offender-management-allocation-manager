require 'rails_helper'

describe Allocation::FakeAllocationRecord do
  describe 'Generating a fake allocation record' do
    it 'returns a record with tiering information' do
      staff_id = '1234569'

      record = Allocation::FakeAllocationRecord.generate(staff_id)

      expect(record.staff_id).to eq(staff_id)
      expect(record.tier_a).to eq(0)
      expect(record.tier_b).to eq(1)
      expect(record.tier_c).to eq(0)
      expect(record.tier_d).to eq(1)
      expect(record.total_cases).to eq(2)
    end
  end
end
