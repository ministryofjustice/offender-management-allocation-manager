require 'rails_helper'

RSpec.describe AllocationVersion, type: :model do
  let(:nomis_staff_id) { 456_789 }
  let(:nomis_offender_id) { 123_456 }

  let(:attributes) {
    {
      nomis_offender_id: nomis_offender_id,
      prison: 'LEI',
      allocated_at_tier: 'A',
      primary_pom_name: 'Bob Jones',
      primary_pom_nomis_id: nomis_staff_id,
      nomis_booking_id: 896_456,
      event: 0,
      event_trigger: 0
    }
  }

  let!(:allocation) { AllocationVersion.create!(attributes) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:nomis_booking_id) }
    it { is_expected.to validate_presence_of(:prison) }
    it { is_expected.to validate_presence_of(:allocated_at_tier) }
    it { is_expected.to validate_presence_of(:event) }
    it { is_expected.to validate_presence_of(:event_trigger) }
  end

  describe 'Versions' do
    it 'creates a version when updating a record', versioning: true do
      expect(allocation.versions.count).to be(1)

      allocation.update(allocated_at_tier: 'B')

      expect(allocation.versions.count).to be(2)
      expect(allocation.versions.last.reify.allocated_at_tier).to eq('A')
    end
  end

  describe '#active?' do
    it 'return true if an Allocation has been assigned a Primary POM' do
      expect(AllocationVersion.active?(nomis_offender_id)).to be(true)
    end

    it 'return false if an Allocation has not been assigned a Primary POM' do
      AllocationVersion.deallocate_primary_pom(nomis_staff_id)

      expect(AllocationVersion.active?(nomis_offender_id)).to be(false)
    end
  end
end
