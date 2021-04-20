require 'rails_helper'

RSpec.describe Allocation, type: :model do
  let(:nomis_staff_id) { 456_789 }
  let(:nomis_offender_id) { 'A3434LK' }
  let(:another_nomis_offender_id) { 654_321 }

  describe '#without_ldu_emails' do
    # CRC offender with no team
    let!(:crc_without_team) {
      case_info = create(:case_information, case_allocation: 'CRC', team: nil)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # CRC offender with a team/LDU with no email address
    let!(:crc_without_email) {
      blank_team = create(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))
      case_info = create(:case_information, case_allocation: 'CRC', team: blank_team)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # NPS offender with no team
    let!(:nps_without_team) {
      case_info = create(:case_information, team: nil)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # NPS offender with a team/LDU with no email address
    let!(:nps_without_email) {
      ldu = create(:local_divisional_unit, email_address: nil)
      team = create(:team, local_divisional_unit: ldu)
      case_info = create(:case_information, team: team)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # NPS offender with a team/LDU that has an email address
    let!(:nps_with_email) {
      ldu = create(:local_divisional_unit, email_address: 'someone@example.com')
      team = create(:team, local_divisional_unit: ldu)
      case_info = create(:case_information, team: team)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # NPS offender with a new LocalDeliveryUnit, but no Team
    let!(:nps_with_new_ldu) {
      ldu = create(:local_delivery_unit)
      case_info = create(:case_information, team: nil, local_delivery_unit: ldu)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    # NPS offender with a new LocalDeliveryUnit and a Team/LDU with no email address
    let!(:nps_with_new_ldu_and_bad_team) {
      ldu = create(:local_delivery_unit)
      team = create(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil))
      case_info = create(:case_information, team: team, local_delivery_unit: ldu)
      create(:allocation, nomis_offender_id: case_info.nomis_offender_id)
    }

    it 'picks up NPS allocations without emails' do
      expect(described_class.without_ldu_emails).to match_array([nps_without_team, nps_without_email])
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:prison) }
    it { is_expected.to validate_presence_of(:allocated_at_tier) }
    it { is_expected.to validate_presence_of(:event) }
    it { is_expected.to validate_presence_of(:event_trigger) }
  end

  context 'with allocations' do
    let(:prison) { build(:prison) }
    let(:pom) { build(:pom, staffId: nomis_staff_id) }

    let!(:allocation) {
      create(
        :allocation,
        prison: prison.code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
      )
    }

    describe 'Versions' do
      it 'creates a version when updating a record' do
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
          prison: allocation.prison,
          nomis_offender_id: another_nomis_offender_id,
          primary_pom_nomis_id: 485_926,
          secondary_pom_nomis_id: nomis_staff_id,
          override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
        )
      }

      it 'removes them as the primary pom\'s from all allocations' do
        described_class.deallocate_primary_pom(nomis_staff_id, allocation.prison)

        deallocation = described_class.find_by!(nomis_offender_id: nomis_offender_id)

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

    describe 'when an offender moves prison'  do
      before do
        stub_auth_token
        stub_poms(prison_code, poms)

        stub_spo_user build(:pom, firstName: "MOIC", lastName: 'POM')
        stub_offender(offender)
      end

      let(:nomis_offender_id) { 'G2911GD' }
      let(:prison_code) { build(:prison).code }
      let(:poms) { [build(:pom, staffId: 485_833)] }
      let(:offender) { build(:nomis_offender, offenderNo: nomis_offender_id) }

      it 'removes the primary pom details in an Offender\'s allocation' do
        create(:case_information, nomis_offender_id: nomis_offender_id)

        params = {
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: DateTime.now.utc,
          recommended_pom_type: 'probation',
          event: Allocation::ALLOCATE_PRIMARY_POM,
          created_by_username: 'MOIC_POM',
          event_trigger: Allocation::USER
        }
        AllocationService.create_or_update(params)
        alloc = described_class.find_by!(nomis_offender_id: nomis_offender_id)

        alloc.dealloate_offender_after_transfer
        deallocation = alloc.reload

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq 'offender_transferred'
      end

      it 'when an offender is released from prison removes the primary pom details in an Offender\'s allocation' do
        create(:case_information, nomis_offender_id: nomis_offender_id)

        params = {
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: DateTime.now.utc,
          recommended_pom_type: 'probation',
          event: Allocation::ALLOCATE_PRIMARY_POM,
          event_trigger: Allocation::USER,
          created_by_username: 'MOIC_POM'
        }
        AllocationService.create_or_update(params)

        alloc = described_class.find_by(nomis_offender_id: nomis_offender_id)
        alloc.deallocate_offender_after_release
        deallocation = alloc.reload

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq 'offender_released'

        # We expect the offender's prison to be left intact and not removed. This will
        # allow us to track which institution an offender was released from.
        expect(deallocation.prison).to eq prison_code
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
          prison: allocation.prison,
          secondary_pom_nomis_id: nomis_staff_id
        )
      }
      let!(:another_allocation) {
        create(
          :allocation,
          prison: allocation.prison,
          primary_pom_nomis_id: 27
        )
      }
      let!(:another_prison) {
        create(
          :allocation,
          primary_pom_nomis_id: nomis_staff_id,
          prison: 'RSI'
        )
      }

      it 'returns both primary and secondary allocations' do
        expect(described_class.active_pom_allocations(nomis_staff_id, allocation.prison)).to match_array [secondary_allocation, allocation]
      end
    end
  end

  describe 'automate pushing the primary pom to ndelius', :push_pom_to_delius do
    let(:prison) { build(:prison).code }

    context 'when a new allocation is created and a POM is set' do
      before do
        expect(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:staff_detail).with(nomis_staff_id).and_return build(:pom, firstName: 'Bill', lastName: 'Jones')
        expect(HmppsApi::CommunityApi).to receive(:set_pom).with offender_no: nomis_offender_id, prison: prison, forename: 'Bill', surname: 'Jones'
      end

      it 'pushes the POM name to Ndelius'do
        create(:allocation, :primary, nomis_offender_id: nomis_offender_id, prison: prison, primary_pom_nomis_id: nomis_staff_id)
      end
    end

    context 'with an existing allocation' do
      before do
        expect(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:staff_detail).with(nomis_staff_id).and_return build(:pom, firstName: 'Bill', lastName: 'Jones')
        expect(HmppsApi::CommunityApi).to receive(:set_pom).with offender_no: nomis_offender_id, prison: prison, forename: 'Bill', surname: 'Jones'
        create(:allocation, :primary, nomis_offender_id: nomis_offender_id, prison: prison, primary_pom_nomis_id: nomis_staff_id)
      end

      let(:allocation) { described_class.last }

      describe 'updating secondary POM' do
        it 'doesnt update delius' do
          allocation.update!(secondary_pom_nomis_id: 24689)
        end
      end

      describe 'de-allocated POM' do
        before do
          expect(HmppsApi::CommunityApi).to receive(:unset_pom).with nomis_offender_id
        end

        it 'deletes the POM from Ndelius' do
          allocation.update!(primary_pom_nomis_id: nil)
        end
      end

      describe 're-allocated POM ' do
        before do
          expect(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:staff_detail).with(updated_nomis_staff_id).and_return build(:pom, firstName: 'Sally', lastName: 'Albright')
          expect(HmppsApi::CommunityApi).to receive(:set_pom).with offender_no: nomis_offender_id, prison: prison, forename: 'Sally', surname: 'Albright'
        end

        let(:updated_nomis_staff_id) { 146890 }

        it 'updates the POM in Ndelius' do
          allocation.update!(primary_pom_nomis_id: updated_nomis_staff_id)
        end
      end
    end
  end
end
