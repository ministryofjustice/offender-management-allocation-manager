# frozen_string_literal: true

RSpec.describe PrisonerMergeService do
  subject(:service) do
    described_class.new(
      old_offender_id: old_id,
      new_offender_id: new_id
    )
  end

  let(:old_id) { 'A3646EA' }
  let(:new_id) { 'A3645EA' }

  shared_context 'with old offender' do
    let!(:old_offender) { create(:offender, nomis_offender_id: old_id) }
  end

  before do
    allow(Rails.logger).to receive(:info)
    stub_feature_flag(:prisoner_merges, enabled: true)
  end

  def expect_migrated_records(model_class, count: nil)
    aggregate_failures do
      expect(model_class.where(nomis_offender_id: old_id)).to be_empty
      expect(model_class.where(nomis_offender_id: new_id)).to be_present
      expect(model_class.where(nomis_offender_id: new_id).count).to eq(count) if count
    end
  end

  def expect_existing_record_unchanged(model_class, attribute, expected_value)
    aggregate_failures do
      expect(model_class.find_by!(nomis_offender_id: new_id).public_send(attribute)).to eq(expected_value)
      expect(model_class.find_by(nomis_offender_id: old_id)).to be_present
    end
  end

  def expect_logged_info(pattern)
    expect(Rails.logger).to have_received(:info).with(a_string_matching(pattern))
  end

  def expect_conflict_logged(record_type)
    expect_logged_info(/event=migrate_record_conflict.*record=#{record_type}.*old_nomis_id=#{old_id}.*canonical_id=#{new_id}/)
  end

  def create_orphaned_record(factory)
    offender = create(:offender, nomis_offender_id: old_id)
    create(factory, offender:)
    Offender.where(nomis_offender_id: old_id).delete_all # bypass dependent: :destroy callbacks
  end

  def migrated_record_audits(record_type)
    AuditEvent.where("ARRAY[?]::text[] <@ tags", %w[service prisoner_merge migrated] + [record_type])
  end

  describe '.locally_tracked?' do
    subject(:tracked?) { described_class.locally_tracked?(old_id) }

    it 'returns false when the NOMIS ID has no local state at all' do
      expect(tracked?).to be false
    end

    it 'returns true when there is an Offender row' do
      create(:offender, nomis_offender_id: old_id)
      expect(tracked?).to be true
    end

    it 'returns true when there is an AllocationHistory row but no Offender (orphan)' do
      create(:allocation_history, nomis_offender_id: old_id, prison: create(:prison).code, primary_pom_nomis_id: 485_926)
      expect(tracked?).to be true
    end

    it 'returns true when there is a calculated handover date but no Offender (orphan)' do
      create_orphaned_record(:calculated_handover_date)
      expect(tracked?).to be true
    end

    it 'returns true when there is a parole review but no Offender' do
      create_orphaned_record(:parole_review)
      expect(tracked?).to be true
    end
  end

  describe 'bulk reassignable model migration' do
    include_context 'with old offender'

    context 'when old ID has early allocations' do
      let!(:early_alloc1) { create(:early_allocation, offender: old_offender) }
      let!(:early_alloc2) { create(:early_allocation, offender: old_offender) }

      it 'moves all early allocations to the canonical ID' do
        service.process

        expect_migrated_records(EarlyAllocation, count: 2)
      end

      it 'logs the bulk migration with count' do
        service.process

        expect_logged_info(/event=migrate_bulk_records.*record=early_allocation.*count=2/)
      end

      it 'reassigns early allocations even when validations would fail on save' do
        early_alloc1.update_columns(community_decision: nil)
        early_alloc2.update_columns(community_decision: nil)

        expect { service.process }.not_to raise_error
        expect_migrated_records(EarlyAllocation, count: 2)
      end
    end

    context 'when old ID has victim liaison officers' do
      let!(:vlo1) { create(:victim_liaison_officer, offender: old_offender) }
      let!(:vlo2) { create(:victim_liaison_officer, offender: old_offender) }

      it 'moves all VLOs to the canonical ID' do
        service.process

        expect_migrated_records(VictimLiaisonOfficer, count: 2)
      end

      it 'creates paper trail versions for each reassigned VLO record' do
        version_counts_by_item_before = PaperTrail::Version.group(:item_type, :item_id).count

        service.process

        [vlo1, vlo2].each do |vlo|
          before_count = version_counts_by_item_before.fetch(['VictimLiaisonOfficer', vlo.id], 0)
          after_count = PaperTrail::Version.where(item_type: 'VictimLiaisonOfficer', item_id: vlo.id).count
          expect(after_count).to eq(before_count + 1)
        end
      end
    end

    context 'when old ID has no bulk records' do
      it 'does not log a bulk migration event' do
        service.process

        expect(Rails.logger).not_to have_received(:info).with(/event=migrate_bulk_records/)
      end
    end
  end

  describe 'calculated handover date migration' do
    include_context 'with old offender'

    context 'when old ID has a calculated handover date and new ID does not' do
      let!(:old_handover_date) { create(:calculated_handover_date, offender: old_offender, reason: 'pre_omic_rules') }

      it 'moves the calculated handover date to the canonical ID' do
        service.process

        expect_migrated_records(CalculatedHandoverDate, count: 1)
      end
    end

    context 'when new ID already has a calculated handover date' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }
      let!(:old_handover_date) { create(:calculated_handover_date, offender: old_offender, reason: 'pre_omic_rules') }
      let!(:new_handover_date) { create(:calculated_handover_date, offender: new_offender, reason: 'determinate_parole') }

      it 'does not overwrite the existing canonical handover date' do
        service.process

        expect_existing_record_unchanged(CalculatedHandoverDate, :reason, 'determinate_parole')
      end
    end
  end

  describe 'parole review migration' do
    include_context 'with old offender'

    context 'when old ID has reviews and canonical ID does not' do
      let!(:review1) { create(:parole_review, offender: old_offender, review_id: 500_001) }
      let!(:review2) { create(:parole_review, offender: old_offender, review_id: 500_002) }

      it 'moves all parole reviews to the canonical ID' do
        service.process

        expect_migrated_records(ParoleReview, count: 2)
      end

      it 'logs migrated and deleted counts' do
        service.process

        expect_logged_info(/event=migrate_parole_reviews.*record=parole_review.*migrated=2.*deleted=0/)
      end
    end

    context 'when canonical ID already has one of the same review IDs' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }

      before do
        # Duplicate logical review across both NOMIS IDs
        create(:parole_review, offender: old_offender, review_id: 500_010)
        create(:parole_review, offender: new_offender, review_id: 500_010)
        # Non-conflicting old review that should migrate
        create(:parole_review, offender: old_offender, review_id: 500_011)
      end

      it 'deletes old duplicates then migrates remaining records without raising' do
        expect { service.process }.not_to raise_error

        aggregate_failures do
          expect(ParoleReview.exists?(nomis_offender_id: old_id, review_id: 500_010)).to be false
          expect(ParoleReview.exists?(nomis_offender_id: new_id, review_id: 500_010)).to be true
          expect(ParoleReview.exists?(nomis_offender_id: old_id, review_id: 500_011)).to be false
          expect(ParoleReview.exists?(nomis_offender_id: new_id, review_id: 500_011)).to be true
        end
      end

      it 'logs both migrated and deleted counts' do
        service.process

        expect_logged_info(/event=migrate_parole_reviews.*record=parole_review.*migrated=1.*deleted=1/)
      end
    end
  end

  describe 'merge record tracking' do
    it 'records the merge in the database' do
      expect { service.process }
        .to change(NomisIdMerge, :count).by(1)
    end

    describe 'feature flag: prisoner_merges' do
      before do
        stub_feature_flag(:prisoner_merges, enabled: false)
      end

      it 'records merge mapping but skips record reassignment' do
        old_offender = create(:offender, nomis_offender_id: old_id)
        create(:case_information, :manual_entry, offender: old_offender)

        expect { service.process }.to change(NomisIdMerge, :count).by(1)
        expect(CaseInformation.find_by(nomis_offender_id: old_id)).to be_present
        expect(CaseInformation.find_by(nomis_offender_id: new_id)).to be_nil
      end
    end

    it 'stores the correct old and new NOMIS IDs' do
      service.process

      merge = NomisIdMerge.find_by!(old_nomis_id: old_id)
      expect(merge.new_nomis_id).to eq(new_id)
    end

    it 'is idempotent when processed more than once' do
      service.process
      expect { service.process }.not_to change(NomisIdMerge, :count)
    end

    it 'creates the canonical offender row when it does not exist yet' do
      create(:offender, nomis_offender_id: old_id)
      create(:responsibility, nomis_offender_id: old_id)

      expect { service.process }
        .to change { Offender.exists?(nomis_offender_id: new_id) }
        .from(false).to(true)
    end

    it 'rolls back all merge writes if a table migration fails' do
      old_offender = create(:offender, nomis_offender_id: old_id)
      create(:case_information, :manual_entry, offender: old_offender)

      allow_any_instance_of(CaseInformation).to receive(:save!).and_raise(StandardError, 'boom')

      expect { service.process }.to raise_error(StandardError, 'boom')

      aggregate_failures do
        expect(NomisIdMerge.find_by(old_nomis_id: old_id)).to be_nil
        expect(Offender.find_by(nomis_offender_id: new_id)).to be_nil
        expect(CaseInformation.find_by(nomis_offender_id: old_id)).to be_present
        expect(CaseInformation.find_by(nomis_offender_id: new_id)).to be_nil
        expect(migrated_record_audits('case_information').where(nomis_offender_id: new_id)).to be_empty
      end
    end

    it 'bubbles up RecordNotUnique and rolls back all merge writes' do
      old_offender = create(:offender, nomis_offender_id: old_id)
      create(:case_information, :manual_entry, offender: old_offender)

      allow_any_instance_of(CaseInformation).to receive(:save!)
        .and_raise(ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint')

      expect { service.process }.to raise_error(ActiveRecord::RecordNotUnique)

      aggregate_failures do
        expect(NomisIdMerge.find_by(old_nomis_id: old_id)).to be_nil
        expect(Offender.find_by(nomis_offender_id: new_id)).to be_nil
        expect(CaseInformation.find_by(nomis_offender_id: old_id)).to be_present
        expect(CaseInformation.find_by(nomis_offender_id: new_id)).to be_nil
        expect(migrated_record_audits('case_information').where(nomis_offender_id: new_id)).to be_empty
      end
    end
  end

  describe 'canonical ID resolution' do
    it 'records the new merge and resolves the end-of-chain canonical ID' do
      create(:nomis_id_merge, old_nomis_id: 'A9999ZZ', new_nomis_id: old_id)

      service.process

      expect(NomisIdMerge.canonical_id_for('A9999ZZ')).to eq(new_id)
    end

    it 'migrates records to the end-of-chain canonical ID' do
      canonical_id = 'A1111AA'
      create(:offender, nomis_offender_id: old_id)
      create(:responsibility, nomis_offender_id: old_id)
      create(:nomis_id_merge, old_nomis_id: new_id, new_nomis_id: canonical_id)

      service.process

      aggregate_failures do
        expect(Responsibility.find_by(nomis_offender_id: canonical_id)).to be_present
        expect(Responsibility.find_by(nomis_offender_id: new_id)).to be_nil
        expect(Responsibility.find_by(nomis_offender_id: old_id)).to be_nil
        expect(Offender.find_by(nomis_offender_id: canonical_id)).to be_present
      end
    end
  end

  describe 'handover progress checklist migration' do
    include_context 'with old offender'

    context 'when old ID has a checklist and new ID does not' do
      let!(:checklist) do
        HandoverProgressChecklist.create!(
          nomis_offender_id: old_id,
          reviewed_oasys: true,
          contacted_com: false,
          attended_handover_meeting: false,
          sent_handover_report: false
        )
      end

      it 'moves checklist to canonical ID' do
        service.process

        expect_migrated_records(HandoverProgressChecklist, count: 1)
      end
    end

    context 'when new ID already has a checklist' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }
      let!(:old_checklist) do
        HandoverProgressChecklist.create!(
          nomis_offender_id: old_id,
          reviewed_oasys: true,
          contacted_com: false,
          attended_handover_meeting: false,
          sent_handover_report: false
        )
      end
      let!(:new_checklist) do
        HandoverProgressChecklist.create!(
          nomis_offender_id: new_id,
          reviewed_oasys: false,
          contacted_com: true,
          attended_handover_meeting: false,
          sent_handover_report: false
        )
      end

      it 'does not overwrite new checklist' do
        service.process

        expect_existing_record_unchanged(HandoverProgressChecklist, :contacted_com, true)
      end

      it 'leaves old checklist under original ID' do
        service.process

        expect(HandoverProgressChecklist.find_by(nomis_offender_id: old_id)).to be_present
      end
    end
  end

  describe 'responsibility migration' do
    include_context 'with old offender'

    context 'when old ID has responsibility and new ID does not' do
      let!(:responsibility) { create(:responsibility, nomis_offender_id: old_id) }

      it 'moves responsibility to canonical ID' do
        service.process

        expect_migrated_records(Responsibility, count: 1)
      end
    end

    context 'when new ID already has responsibility' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }
      let!(:old_responsibility) { create(:responsibility, :pom, nomis_offender_id: old_id) }
      let!(:new_responsibility) { create(:responsibility, :com, nomis_offender_id: new_id) }

      it 'does not overwrite new responsibility' do
        service.process

        expect_existing_record_unchanged(Responsibility, :value, 'Probation')
      end

      it 'logs a conflict for observability' do
        service.process

        expect_conflict_logged('responsibility')
      end
    end
  end

  describe 'case information migration' do
    include_context 'with old offender'

    context 'when old ID has manual case info and new ID does not' do
      let!(:manual_case_info) { create(:case_information, :manual_entry, offender: old_offender) }

      it 'moves case information to canonical ID' do
        service.process

        expect_migrated_records(CaseInformation, count: 1)
      end

      it 'creates a paper trail version that captures nomis_offender_id reassignment' do
        before_count = manual_case_info.versions.count

        service.process

        expect(manual_case_info.reload.versions.count).to eq(before_count + 1)

        changeset = YAML.unsafe_load(manual_case_info.reload.versions.last.object_changes)
        expect(changeset['nomis_offender_id']).to eq([old_id, new_id])
      end
    end

    context 'when old ID has auto-imported case information and new ID does not' do
      let!(:auto_case_info) { create(:case_information, offender: old_offender, manual_entry: false) }

      it 'migrates it to the canonical ID' do
        service.process

        expect_migrated_records(CaseInformation, count: 1)
      end
    end

    context 'when new ID already has case information' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }
      let!(:old_case_info) { create(:case_information, offender: old_offender, tier: 'B') }
      let!(:new_case_info) { create(:case_information, offender: new_offender, tier: 'A') }

      it 'does not overwrite the existing case information' do
        service.process

        expect_existing_record_unchanged(CaseInformation, :tier, 'A')
      end
    end
  end

  describe 'allocation history migration' do
    include_context 'with old offender'
    let(:prison_code) { create(:prison).code }

    context 'when old ID has allocation history and new ID does not' do
      let!(:allocation_history) do
        create(:allocation_history, nomis_offender_id: old_id, prison: prison_code, primary_pom_nomis_id: 485_926)
      end

      it 'moves allocation history to canonical ID' do
        service.process

        expect_migrated_records(AllocationHistory, count: 1)
      end

      it 'does not publish allocation.changed as primary POM assignment is unchanged' do
        expect_any_instance_of(DomainEvents::Event).not_to receive(:publish)
        service.process
      end
    end

    context 'when new ID already has allocation history' do
      let!(:new_offender) { create(:offender, nomis_offender_id: new_id) }
      let!(:old_allocation_history) do
        create(:allocation_history,
               nomis_offender_id: old_id,
               prison: prison_code,
               event: AllocationHistory::ALLOCATE_PRIMARY_POM,
               primary_pom_nomis_id: 485_926)
      end
      let!(:new_allocation_history) do
        create(:allocation_history,
               nomis_offender_id: new_id,
               prison: prison_code,
               event: AllocationHistory::DEALLOCATE_RELEASED_OFFENDER,
               primary_pom_nomis_id: nil)
      end

      it 'does not overwrite existing allocation history' do
        service.process

        expect_existing_record_unchanged(AllocationHistory, :event, 'deallocate_released_offender')
      end

      it 'leaves old allocation history under original ID' do
        service.process

        expect(AllocationHistory.find_by(nomis_offender_id: old_id)).to be_present
      end
    end
  end

  describe 'logging' do
    it 'emits record_merge log with context and canonical ID' do
      service.process

      expect_logged_info(/event=record_merge.*service=prisoner_merge_service.*old_offender_id=#{old_id}.*new_offender_id=#{new_id}.*canonical_id=#{new_id}/)
    end
  end

  describe 'audit traceability' do
    it 'publishes an audit event when merge mapping is recorded via model callbacks' do
      service.process

      audit = AuditEvent
                .where('ARRAY[?]::text[] <@ tags', %w[record nomis_id_merge created])
                .order(:created_at)
                .last
      nomis_offender_id = audit&.nomis_offender_id
      data = audit&.data
      tags = audit&.tags

      aggregate_failures do
        expect(audit).to be_present
        expect(tags).to include('record', 'nomis_id_merge', 'created')
        expect(nomis_offender_id).to eq(old_id)
        expect(data['canonical_id']).to eq(new_id)
        expect(data['before']).to include('old_nomis_id' => nil, 'new_nomis_id' => nil)
        expect(data['after']).to include('old_nomis_id' => old_id, 'new_nomis_id' => new_id)
      end
    end

    it 'publishes the merge-mapping audit event when there are no records to reassign' do
      service.process

      tags_list = AuditEvent.order(:created_at).pluck(:tags)

      expect(tags_list).to include(include('record', 'nomis_id_merge', 'created'))
    end

    it 'publishes an audit event when case information is migrated' do
      old_offender = create(:offender, nomis_offender_id: old_id)
      create(:case_information, :manual_entry, offender: old_offender)

      service.process

      audit = migrated_record_audits('case_information').order(:created_at).last
      data = audit&.data
      tags = audit&.tags

      aggregate_failures do
        expect(audit).to be_present
        expect(tags).to include('service', 'prisoner_merge', 'migrated', 'case_information')
        expect(data['old_offender_id']).to eq(old_id)
        expect(data['new_offender_id']).to eq(new_id)
        expect(data['canonical_id']).to eq(new_id)
      end
    end
  end
end
