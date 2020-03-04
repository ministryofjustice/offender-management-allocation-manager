require 'rails_helper'

RSpec.describe Allocation, type: :model do
  let(:nomis_staff_id) { 456_789 }
  let(:nomis_offender_id) { 123_456 }
  let(:another_nomis_offender_id) { 654_321 }

  describe '#without_ldu_emails' do
    let!(:c1) {
      ci = create(:case_information, probation_service: 'Scotland', team: nil)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)
    }
    let!(:c2) {
      ldu = create(:local_divisional_unit, email_address: nil)
      team = create(:team, local_divisional_unit: ldu)
      ci = create(:case_information, team: team)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)
    }
    let!(:c3) {
      ldu = create(:local_divisional_unit, email_address: 'someone@example.com')
      team = create(:team, local_divisional_unit: ldu)
      ci = create(:case_information, team: team)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)
    }

    it 'picks up allocations without emails' do
      expect(described_class.without_ldu_emails).to match_array([c1, c2])
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:nomis_booking_id) }
    it { is_expected.to validate_presence_of(:prison) }
    it { is_expected.to validate_presence_of(:allocated_at_tier) }
    it { is_expected.to validate_presence_of(:event) }
    it { is_expected.to validate_presence_of(:event_trigger) }
  end

  context 'with allocations' do
    let!(:allocation) {
      create(
        :allocation,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
      )
    }

    describe 'Versions' do
      it 'creates a version when updating a record', versioning: true do
        expect(allocation.versions.count).to be(1)

        allocation.update(allocated_at_tier: 'B')

        expect(allocation.versions.count).to be(2)
        expect(allocation.versions.last.reify.allocated_at_tier).to eq('A')
      end
    end

    describe 'when a POM is inactive' do
      let!(:another_allocaton) {
        create(
          :allocation,
          nomis_offender_id: another_nomis_offender_id,
          primary_pom_nomis_id: 485_926,
          secondary_pom_nomis_id: nomis_staff_id,
          override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
        )
      }

      it 'removes them as the primary pom\'s from all allocations' do
        described_class.deallocate_primary_pom(nomis_staff_id, allocation.prison)

        deallocation = described_class.find_by(nomis_offender_id: nomis_offender_id)

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
      end

      it 'removes them as the secondary pom from all allocations' do
        described_class.deallocate_secondary_pom(nomis_staff_id, allocation.prison)

        deallocation = described_class.find_by(nomis_offender_id: another_nomis_offender_id)

        expect(deallocation.secondary_pom_nomis_id).to be_nil
        expect(deallocation.secondary_pom_name).to be_nil
      end
    end

    describe 'when an offender moves prison', versioning: true, vcr: { cassette_name: :allocation_deallocate_offender }  do
      it 'removes the primary pom details in an Offender\'s allocation' do
        nomis_offender_id = 'G2911GD'
        movement_type = Allocation::OFFENDER_TRANSFERRED
        params = {
          nomis_offender_id: nomis_offender_id,
          prison: 'LEI',
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: DateTime.now.utc,
          nomis_booking_id: 1,
          recommended_pom_type: 'probation',
          event: Allocation::ALLOCATE_PRIMARY_POM,
          created_by_username: 'PK000223',
          event_trigger: Allocation::USER
        }
        AllocationService.create_or_update(params)
        alloc = described_class.find_by!(nomis_offender_id: nomis_offender_id)

        alloc.deallocate_offender(movement_type)
        deallocation = alloc.reload

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq 'offender_transferred'
      end
    end

    describe 'when an offender gets released from prison', versioning: true, vcr: { cassette_name: :allocation_deallocate_offender_released }  do
      it 'removes the primary pom details in an Offender\'s allocation' do
        nomis_offender_id = 'G2911GD'
        movement_type = Allocation::OFFENDER_RELEASED
        params = {
          nomis_offender_id: nomis_offender_id,
          prison: 'LEI',
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: DateTime.now.utc,
          nomis_booking_id: 1,
          recommended_pom_type: 'probation',
          event: Allocation::ALLOCATE_PRIMARY_POM,
          event_trigger: Allocation::USER,
          created_by_username: 'PK000223'
        }
        AllocationService.create_or_update(params)

        alloc = described_class.find_by(nomis_offender_id: nomis_offender_id)
        alloc.deallocate_offender(movement_type)
        deallocation = alloc.reload

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq 'offender_released'

        # We expect the offender's prison to be left intact and not removed. This will
        # allow us to track which institution an offender was released from.
        expect(deallocation.prison).to eq 'LEI'
      end
    end

    describe 'cleaning up old broken data' do
      let!(:offender_no) { 'G2911GD' }
      let!(:movement) {
        create(:movement,
               offender_no: offender_no,
               direction_code: 'OUT',
               movement_type: 'REL',
               to_agency: 'OUT',
               from_agency: 'BAI')
      }
      let!(:alloc) {
        a = build(
          :allocation,
          nomis_offender_id: offender_no,
          primary_pom_nomis_id: '12345',
          prison: nil
        )
        a.save(validate: false)
        a
      }

      it 'will set the prison when released' do
        allow(Nomis::Elite2::MovementApi).to receive(:movements_for).and_return([movement])

        alloc = described_class.find_by(nomis_offender_id: offender_no)
        alloc.deallocate_offender(Allocation::OFFENDER_RELEASED)

        updated_allocation = alloc.reload
        expect(updated_allocation.prison).not_to be_nil
        expect(updated_allocation.prison).to eq('BAI')
      end

      it 'will set the prison when transferred',
         vcr: { cassette_name: :allocation_transfer_prison_fix } do
        alloc = described_class.find_by(nomis_offender_id: offender_no)
        alloc.deallocate_offender(Allocation::OFFENDER_TRANSFERRED)

        updated_allocation = alloc.reload
        expect(updated_allocation.prison).not_to be_nil
        expect(updated_allocation.prison).to eq('LEI')
      end
    end

    describe '#active?' do
      it 'return true if an Allocation has been assigned a Primary POM' do
        alloc = AllocationService.current_allocation_for(nomis_offender_id)
        expect(alloc.active?).to be(true)
      end

      it 'return false if an Allocation has not been assigned a Primary POM' do
        described_class.deallocate_primary_pom(nomis_staff_id, allocation.prison)
        alloc = AllocationService.current_allocation_for(nomis_offender_id)

        expect(alloc.active?).to be(false)
      end
    end

    describe '#override_reasons' do
      let!(:allocation_no_overrides) {
        create(
          :allocation,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: nomis_staff_id
        )
      }

      it 'returns an array' do
        expect(allocation.override_reasons).to eq %w[suitability no_staff continuity other]
      end

      it 'can handle an allocation without any override reasons' do
        expect(allocation_no_overrides.override_reasons).to eq nil
      end
    end

    describe '#active_pom_allocations' do
      let!(:secondary_allocation) {
        create(
          :allocation,
          nomis_offender_id: nomis_offender_id,
          secondary_pom_nomis_id: nomis_staff_id
        )
      }
      let!(:another_allocation) {
        create(
          :allocation,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: 27
        )
      }
      let!(:another_prison) {
        create(
          :allocation,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: nomis_staff_id,
          prison: 'RSI'
        )
      }

      it 'returns both primary and secondary allocations' do
        expect(described_class.active_pom_allocations(nomis_staff_id, 'LEI')).to match_array [secondary_allocation, allocation]
      end
    end
  end
end
