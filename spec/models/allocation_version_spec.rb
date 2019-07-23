require 'rails_helper'

RSpec.describe AllocationVersion, type: :model do
  let(:nomis_staff_id) { 456_789 }
  let(:nomis_offender_id) { 123_456 }

  let!(:allocation) {
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: nomis_staff_id,
      override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
    )
  }

  let!(:allocation_no_overrides) {
    create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: nomis_staff_id
    )
  }

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

  describe 'when a Primary Pom is inactive' do
    it 'removes the primary pom\'s from all allocations' do
      AllocationVersion.deallocate_primary_pom(nomis_staff_id)

      deallocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

      expect(deallocation.primary_pom_nomis_id).to be_nil
      expect(deallocation.primary_pom_name).to be_nil
      expect(deallocation.primary_pom_allocated_at).to be_nil
      expect(deallocation.recommended_pom_type).to be_nil
    end
  end

  describe 'when an offender moves prison', versioning: true, vcr: { cassette_name: :allocation_version_deallocate_offender }  do
    it 'removes the primary pom details in an Offender\'s allocation' do
      nomis_offender_id = 'G2911GD'
      movement_type = AllocationVersion::OFFENDER_TRANSFERRED
      params = {
        nomis_offender_id: nomis_offender_id,
        prison: 'LEI',
        allocated_at_tier: 'A',
        primary_pom_nomis_id: 485_833,
        primary_pom_allocated_at: DateTime.now.utc,
        nomis_booking_id: 1,
        recommended_pom_type: 'probation',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      }
      AllocationService.create_or_update(params)

      AllocationVersion.deallocate_offender(nomis_offender_id, movement_type)
      deallocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

      expect(deallocation.primary_pom_nomis_id).to be_nil
      expect(deallocation.primary_pom_name).to be_nil
      expect(deallocation.primary_pom_allocated_at).to be_nil
      expect(deallocation.recommended_pom_type).to be_nil
      expect(deallocation.event_trigger).to eq 'offender_transferred'
    end
  end

  describe 'when an offender gets released from prison', versioning: true, vcr: { cassette_name: :allocation_version_deallocate_offender_released }  do
    it 'removes the primary pom details & prison in an Offender\'s allocation' do
      nomis_offender_id = 'G2911GD'
      movement_type = AllocationVersion::OFFENDER_RELEASED
      params = {
        nomis_offender_id: nomis_offender_id,
        prison: 'LEI',
        allocated_at_tier: 'A',
        primary_pom_nomis_id: 485_833,
        primary_pom_allocated_at: DateTime.now.utc,
        nomis_booking_id: 1,
        recommended_pom_type: 'probation',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      }
      AllocationService.create_or_update(params)

      AllocationVersion.deallocate_offender(nomis_offender_id, movement_type)
      deallocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

      expect(deallocation.primary_pom_nomis_id).to be_nil
      expect(deallocation.primary_pom_name).to be_nil
      expect(deallocation.primary_pom_allocated_at).to be_nil
      expect(deallocation.recommended_pom_type).to be_nil
      expect(deallocation.prison).to be_nil
      expect(deallocation.event_trigger).to eq 'offender_released'
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

  describe '#override_reasons' do
    it 'returns an array' do
      expect(allocation.override_reasons).to eq %w[suitability no_staff continuity other]
    end

    it 'can handle an allocation without any override reasons' do
      expect(allocation_no_overrides.override_reasons).to eq nil
    end
  end
end
