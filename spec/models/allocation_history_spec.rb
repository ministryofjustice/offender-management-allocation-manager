require 'rails_helper'

RSpec.describe AllocationHistory, :enable_allocation_change_publish, type: :model do
  let(:nomis_staff_id) { 456_789 }
  let(:nomis_offender_id) { 'A3434LK' }
  let(:another_nomis_offender_id) { 654_321 }
  let(:fake_domain_event) { double(DomainEvents::Event, publish: nil) }

  before do
    allow(DomainEvents::Event).to receive(:new).and_return(fake_domain_event)
  end

  describe '#without_ldu_emails' do
    let!(:crc_without_email) do
      case_info = create(:case_information, enhanced_resourcing: false, local_delivery_unit: nil)

      create(
        :allocation_history,
        prison: build(:prison).code,
        nomis_offender_id: case_info.nomis_offender_id
      )
    end

    let!(:enhanced_handover_without_email) do
      case_info = create(:case_information, enhanced_resourcing: true, local_delivery_unit: nil)

      create(
        :allocation_history,
        prison: build(:prison).code,
        nomis_offender_id: case_info.nomis_offender_id
      )
    end

    let!(:enhanced_handover_with_email) do
      case_info = create(:case_information, enhanced_resourcing: true)

      create(
        :allocation_history,
        prison: build(:prison).code,
        nomis_offender_id: case_info.nomis_offender_id
      )
    end

    it 'picks up enhanced handover allocations without emails' do
      expect(described_class.without_ldu_emails)
        .to match_array([enhanced_handover_without_email])
    end
  end

  describe 'Validations' do
    subject do
      build(
        :allocation_history,
        prison: create(:prison).code,
        nomis_offender_id: nomis_offender_id
      )
    end

    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:prison) }
    it { is_expected.to validate_presence_of(:allocated_at_tier) }
    it { is_expected.to validate_presence_of(:event) }
    it { is_expected.to validate_presence_of(:event_trigger) }

    it { is_expected.to validate_uniqueness_of :nomis_offender_id }

    context 'when the same POM is Primary and Secondary' do
      let(:allocation) do
        build(
          :allocation_history,
          prison: create(:prison).code,
          nomis_offender_id: nomis_offender_id
        )
      end

      before do
        allocation.primary_pom_nomis_id = nomis_staff_id
        allocation.secondary_pom_nomis_id = nomis_staff_id
      end

      it 'is invalid' do
        expect(allocation).not_to be_valid
        expect(allocation.errors[:primary_pom_nomis_id])
          .to eq(['Primary POM cannot be the same as co-working POM'])
      end
    end
  end

  context 'with allocations' do
    let(:prison) { create(:prison) }
    let(:pom) { build(:pom, staffId: nomis_staff_id) }

    let!(:allocation) do
      create(
        :allocation_history,
        prison: prison.code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
      )
    end

    describe 'Versions' do
      it 'creates a version when updating a record' do
        expect(allocation.versions.count).to be(1)

        allocation.update!(allocated_at_tier: 'B')

        expect(allocation.versions.count).to be(2)
        expect(allocation.versions.last.reify.allocated_at_tier).to eq('A')
      end
    end

    describe 'when a POM is inactive' do
      let!(:another_allocation) do
        create(
          :allocation_history,
          prison: allocation.prison,
          nomis_offender_id: another_nomis_offender_id,
          primary_pom_nomis_id: 485_926,
          secondary_pom_nomis_id: nomis_staff_id,
          override_reasons: "[\"suitability\", \"no_staff\", \"continuity\", \"other\"]"
        )
      end

      it 'removes them as the primary pom from all allocations' do
        described_class.deallocate_primary_pom(nomis_staff_id, allocation.prison)

        deallocation = described_class.find_by!(nomis_offender_id: nomis_offender_id)

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq('user')
      end

      it 'removes them as the secondary pom from all allocations' do
        described_class.deallocate_secondary_pom(nomis_staff_id, allocation.prison)

        deallocation = described_class.find_by(nomis_offender_id: another_nomis_offender_id)

        expect(deallocation.secondary_pom_nomis_id).to be_nil
        expect(deallocation.secondary_pom_name).to be_nil
      end
    end

    describe 'deallocations of primary and secondary POMs' do
      let!(:allocation1) do
        create(:allocation_history,
               prison: prison.code,
               nomis_offender_id: 'A1234A',
               primary_pom_nomis_id: 111,
               secondary_pom_nomis_id: 222)
      end

      let!(:allocation2) do
        create(:allocation_history,
               prison: prison.code,
               nomis_offender_id: 'A1234B',
               primary_pom_nomis_id: 333,
               secondary_pom_nomis_id: 444)
      end

      let!(:allocation3) do
        create(:allocation_history,
               prison: prison.code,
               nomis_offender_id: 'A1234C',
               primary_pom_nomis_id: 222,
               secondary_pom_nomis_id: 555)
      end

      context 'when deallocating primary POMs' do
        it 'only deallocates records where the POM is primary' do
          described_class.deallocate_primary_pom(111, prison)

          allocation1.reload
          allocation3.reload

          # Should deallocate A from allocation1
          expect(allocation1.primary_pom_nomis_id).to be_nil
          # Should NOT affect B in allocation3
          expect(allocation3.primary_pom_nomis_id).to eq(222)
        end

        it 'does not affect records where the POM is secondary' do
          described_class.deallocate_primary_pom(222, prison)

          allocation1.reload
          allocation3.reload

          # Should NOT affect A in allocation1
          expect(allocation1.primary_pom_nomis_id).to eq(111)
          # Should deallocate B from allocation3
          expect(allocation3.primary_pom_nomis_id).to be_nil
        end
      end

      context 'when deallocating secondary POMs' do
        it 'only deallocates records where the POM is secondary' do
          described_class.deallocate_secondary_pom(222, prison)

          allocation1.reload
          allocation3.reload

          # Should deallocate B from allocation1
          expect(allocation1.secondary_pom_nomis_id).to be_nil
          # Should NOT affect E in allocation3
          expect(allocation3.secondary_pom_nomis_id).to eq(555)
        end

        it 'does not affect records where the POM is primary' do
          described_class.deallocate_secondary_pom(222, prison)

          allocation3.reload

          # Should NOT affect B as primary in allocation3
          expect(allocation3.primary_pom_nomis_id).to eq(222)
        end

        it 'correctly deallocates when POM is only secondary' do
          described_class.deallocate_secondary_pom(555, prison)

          allocation3.reload

          # Should deallocate E from allocation3
          expect(allocation3.secondary_pom_nomis_id).to be_nil
          # Should NOT affect B as primary in allocation3
          expect(allocation3.primary_pom_nomis_id).to eq(222)
        end
      end
    end

    describe 'when an offender moves prison'  do
      before do
        stub_filtered_pom(prison_code, poms.first)
        stub_spo_user build(:pom, firstName: "MOIC", lastName: 'POM')
        stub_offender(offender)
      end

      let(:nomis_offender_id) { 'G2911GD' }
      let(:prison_code) { create(:prison).code }
      let(:poms) { [build(:pom, staffId: 485_833, primaryEmail: pom_email)] }
      let(:pom_email) { 'mrpom@example.com' }

      let(:offender) do
        build(:nomis_offender, prisonId: prison_code, prisonerNumber: nomis_offender_id)
      end

      it 'removes the primary pom details in an Offender\'s allocation' do
        create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))

        params = {
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: Time.zone.now.utc,
          recommended_pom_type: 'probation',
          event: AllocationHistory::ALLOCATE_PRIMARY_POM,
          created_by_username: 'MOIC_POM',
          event_trigger: AllocationHistory::USER
        }
        AllocationService.create_or_update(params)
        alloc = described_class.find_by!(nomis_offender_id: nomis_offender_id)

        alloc.deallocate_offender_after_transfer
        deallocation = alloc.reload

        expect(deallocation.primary_pom_nomis_id).to be_nil
        expect(deallocation.primary_pom_name).to be_nil
        expect(deallocation.primary_pom_allocated_at).to be_nil
        expect(deallocation.recommended_pom_type).to be_nil
        expect(deallocation.event_trigger).to eq 'offender_transferred'
      end

      context 'when an offender is released from prison' do
        before do
          create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))

          params = {
            nomis_offender_id: nomis_offender_id,
            prison: prison_code,
            allocated_at_tier: 'A',
            primary_pom_nomis_id: 485_833,
            primary_pom_allocated_at: Time.zone.now.utc,
            recommended_pom_type: 'probation',
            event: AllocationHistory::ALLOCATE_PRIMARY_POM,
            event_trigger: AllocationHistory::USER,
            created_by_username: 'MOIC_POM'
          }
          AllocationService.create_or_update(params)

          allow(PomMailer).to receive(:with).and_return(fake_mailer)
          allow(Rails).to receive(:logger).and_return(fake_logger)

          poms
          alloc.deallocate_offender_after_release
        end

        let(:alloc) { described_class.find_by(nomis_offender_id: nomis_offender_id) }
        let(:deallocation) { alloc.reload }
        let(:fake_mailer) { double(offender_deallocated: double(deliver_later: nil)) }
        let(:fake_logger) { double(error: nil, info: nil) }

        it 'removes the primary pom details in an Offender\'s allocation' do
          expect(deallocation.primary_pom_nomis_id).to be_nil
          expect(deallocation.primary_pom_name).to be_nil
          expect(deallocation.primary_pom_allocated_at).to be_nil
          expect(deallocation.recommended_pom_type).to be_nil
          expect(deallocation.event_trigger).to eq 'offender_released'

          # We expect the offender's prison to be left intact and not removed. This will
          # allow us to track which institution an offender was released from.
          expect(deallocation.prison).to eq prison_code
        end

        it 'sends an email' do
          expect(fake_mailer).to have_received(:offender_deallocated)
        end

        it 'logs no error' do
          expect(fake_logger).not_to have_received(:error)
        end

        context 'when primary POM email is blank' do
          let(:pom_email) { nil }

          it 'sends no email' do
            expect(fake_mailer).not_to have_received(:offender_deallocated)
          end

          it 'logs an error' do
            expect(fake_logger).to have_received(:error)
          end
        end
      end
    end

    describe '#active?' do
      it 'return true if an Allocation has been assigned a Primary POM' do
        alloc = described_class.find_by!(nomis_offender_id: nomis_offender_id)
        expect(alloc.active?).to be(true)
      end

      it 'return false if an Allocation has not been assigned a Primary POM' do
        described_class.deallocate_primary_pom(nomis_staff_id, allocation.prison)
        alloc = described_class.find_by!(nomis_offender_id: nomis_offender_id)

        expect(alloc.active?).to be(false)
      end
    end

    describe '#override_reasons' do
      let!(:allocation_no_overrides) do
        create(
          :allocation_history,
          prison: build(:prison).code,
          primary_pom_nomis_id: nomis_staff_id
        )
      end

      it 'returns an array' do
        expect(allocation.override_reasons).to eq %w[suitability no_staff continuity other]
      end

      it 'can handle an allocation without any override reasons' do
        expect(allocation_no_overrides.override_reasons).to eq nil
      end
    end

    describe '#active_pom_allocations' do
      let!(:secondary_allocation) do
        create(
          :allocation_history,
          prison: allocation.prison,
          secondary_pom_nomis_id: nomis_staff_id
        )
      end
      let!(:another_allocation) do
        create(
          :allocation_history,
          prison: allocation.prison,
          primary_pom_nomis_id: 27
        )
      end
      let!(:another_prison) do
        create(
          :allocation_history,
          primary_pom_nomis_id: nomis_staff_id,
          prison: create(:prison).code
        )
      end

      it 'returns both primary and secondary allocations' do
        expect(described_class.active_pom_allocations(nomis_staff_id, allocation.prison))
          .to match_array([secondary_allocation, allocation])
      end
    end

    describe '#previously_allocated_poms' do
      it "Can get previous poms for an offender where there are some" do
        nomis_offender_id = 'GHF1234'
        previous_primary_pom_nomis_id = 345_567
        updated_primary_pom_nomis_id = 485_926

        allocation = create(
          :allocation_history,
          prison: build(:prison).code,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: previous_primary_pom_nomis_id)

        allocation.update!(
          primary_pom_nomis_id: updated_primary_pom_nomis_id,
          event: AllocationHistory::REALLOCATE_PRIMARY_POM
        )

        staff_ids = allocation.previously_allocated_poms

        expect(staff_ids.count).to eq(1)
        expect(staff_ids.first).to eq(previous_primary_pom_nomis_id)
      end
    end
  end

  describe 'publishing a domain event', :push_pom_to_delius do
    let(:prison_code) { create(:prison).code }

    shared_examples 'publish count' do |count|
      it 'publishes domain event' do
        expect(DomainEvents::Event).to have_received(:new).exactly(count).times.with(
          event_type: 'allocation.changed',
          version: 1,
          description: "A POM allocation has changed",
          detail_url: /\/api\/allocation\/#{nomis_offender_id}\/primary_pom/,
          noms_number: nomis_offender_id,
          additional_information: {
            'staffCode' => anything,
            'prisonId' => prison_code,
            'eventTrigger' => 'user',
          }
        )

        expect(fake_domain_event).to have_received(:publish).exactly(count).times
      end
    end

    # With these following examples, the initial creation of AllocationHistory
    # will cause the publishing of a domain event, so in some cases we'll expect
    # 2 to be published
    context 'when a new allocation is created and a POM is set' do
      before do
        create(
          :allocation_history,
          :primary,
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          primary_pom_nomis_id: nomis_staff_id
        )
      end

      it_behaves_like 'publish count', 1
    end

    context 'with an existing allocation' do
      let!(:allocation) do
        create(
          :allocation_history,
          :primary,
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          primary_pom_nomis_id: nomis_staff_id
        )
      end

      context 'when updating secondary POM' do
        before do
          allocation.update!(secondary_pom_nomis_id: 24_689)
        end

        it_behaves_like 'publish count', 1
      end

      context 'when de-allocating primary POM' do
        before do
          allocation.update!(primary_pom_nomis_id: nil)
        end

        it_behaves_like 'publish count', 2
      end

      context 'when re-allocating primary POM' do
        before do
          allocation.update!(primary_pom_nomis_id: updated_nomis_staff_id)
        end

        let(:updated_nomis_staff_id) { 146_890 }

        it_behaves_like 'publish count', 2
      end
    end
  end

  describe '#previously_allocated_but_now_not?' do
    context 'when the case was never allocated a primary pom' do
      it 'returns false' do
        allocation = described_class.new
        expect(allocation.previously_allocated_but_now_not?).to eq(false)
      end
    end

    context 'when the case has been allocated to a primary pom but has since been deallocated' do
      it 'returns true' do
        allocation = described_class.create(
          nomis_offender_id: 'GA123456',
          prison: 'LEI',
          primary_pom_nomis_id: 123_456,
          primary_pom_name: 'A Pom',
          recommended_pom_type: 'Prison',
          primary_pom_allocated_at: 3.days.ago,
          allocated_at_tier: 'D',
          event: :allocate_primary_pom,
          event_trigger: :user,
        )
        allocation.deallocate_primary_pom
        expect(allocation.previously_allocated_but_now_not?).to eq(true)
      end
    end

    context 'when the case has been allocated to a primary pom and deallocated the secondary pom' do
      it 'returns false as they still have aprimary pom' do
        allocation = described_class.create(
          nomis_offender_id: 'GA123456',
          prison: 'LEI',
          primary_pom_nomis_id: 123_456,
          primary_pom_name: 'A Pom',
          recommended_pom_type: 'Prison',
          primary_pom_allocated_at: 3.days.ago,
          allocated_at_tier: 'D',
          event: :allocate_primary_pom,
          event_trigger: :user,
        )
        allocation.deallocate_secondary_pom
        expect(allocation.previously_allocated_but_now_not?).to eq(false)
      end
    end

    context 'when the case has been allocated to a primary pom, deallocated and then allocated again' do
      it 'returns false' do
        allocation = described_class.create(
          nomis_offender_id: 'GA123456',
          prison: 'LEI',
          primary_pom_nomis_id: 123_456,
          primary_pom_name: 'A Pom',
          recommended_pom_type: 'Prison',
          primary_pom_allocated_at: 3.days.ago,
          allocated_at_tier: 'D',
          event: :allocate_primary_pom,
          event_trigger: :user,
        )
        allocation.deallocate_primary_pom
        allocation.update(
          primary_pom_nomis_id: 923_456,
          primary_pom_name: 'Another Pom',
          primary_pom_allocated_at: 2.days.ago,
          event: :reallocate_primary_pom,
        )
        expect(allocation.previously_allocated_but_now_not?).to eq(false)
      end
    end
  end

  describe 'flattening of paper trail versions upon allocation updates' do
    let(:prison_code) { create(:prison).code }
    let(:allocation) do
      create(:allocation_history, :primary,
             nomis_offender_id: nomis_offender_id,
             prison: prison_code,
             primary_pom_nomis_id: nomis_staff_id)
    end

    it 'creates a flattened version when allocation is updated' do
      expect {
        allocation.update!(allocated_at_tier: 'B')
      }.to change(AllocationHistoryVersion, :count).by(1)

      flattened_version = AllocationHistoryVersion.last
      expect(flattened_version.allocation_history_id).to eq(allocation.id)
    end

    it 'does not create a flattened version when allocation is created' do
      expect {
        create(
          :allocation_history,
          :primary,
          prison: prison_code
        )
      }.not_to change(AllocationHistoryVersion, :count)
    end
  end
end
