require 'rails_helper'

RSpec.describe Allocation, type: :model do
  describe 'associations' do
    subject { build(:allocation) }

    it { is_expected.to belong_to(:offender) }
    it { is_expected.to belong_to(:pom_detail) }
  end

  describe 'scopes' do
    before do
      create_list(:allocation, 11, :primary)
      create_list(:allocation, 7, :coworking)
    end

    it 'can find Primary allocations' do
      records = described_class.primary
      expect(records.count).to eq(11)
      expect(records.map(&:primary?)).to all be(true)
      expect(records.map(&:coworking?)).to all be(false)
    end

    it 'can find Co-Working allocations' do
      records = described_class.coworking
      expect(records.count).to eq(7)
      expect(records.map(&:primary?)).to all be(false)
      expect(records.map(&:coworking?)).to all be(true)
    end
  end

  describe 'validations' do
    let(:offender) { create(:offender) }

    context 'when the offender already has a Primary POM' do
      before do
        create(:allocation, :primary, offender: offender)
      end

      it 'only allows one Primary POM to be allocated' do
        allocation = build(:allocation, :primary, offender: offender)
        expect(allocation).not_to be_valid
        expect(allocation.errors[:offender]).to eq(["The offender already has an allocation of that type"])
      end
    end

    context 'when the offender already has a Co-Working POM' do
      before do
        create(:allocation, :coworking, offender: offender)
      end

      it 'only allows one Co-Working POM to be allocated' do
        allocation = build(:allocation, :coworking, offender: offender)
        expect(allocation).not_to be_valid
        expect(allocation.errors[:offender]).to eq(["The offender already has an allocation of that type"])
      end
    end

    context 'when trying to allocate the same POM as both Primary and Co-Working' do
      let(:pom) { create(:pom_detail) }

      before do
        create(:allocation, :primary, offender: offender, pom_detail: pom)
      end

      it 'does not allow the same POM to be allocated more than once' do
        allocation = build(:allocation, :coworking, offender: offender, pom_detail: pom)
        expect(allocation).not_to be_valid
        expect(allocation.errors[:pom_detail]).to eq(["This POM is already allocated to that offender"])
      end
    end
  end
end
