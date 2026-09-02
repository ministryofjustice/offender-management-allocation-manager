# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auditable do
  before do
    PaperTrail.request.whodunnit = 'TEST_USER'
    stub_feature_flag(:rosh_level, enabled: true)
  end

  after do
    PaperTrail.request.whodunnit = nil
  end

  describe 'with an offender-linked model (CaseInformation)' do
    let!(:case_info) { create(:case_information, :manual_entry, tier: 'B', rosh_level: 'LOW', enhanced_resourcing: false) }

    it 'sets nomis_offender_id from the record' do
      audit = AuditEvent.order(:created_at).last
      expect(audit.nomis_offender_id).to eq(case_info.nomis_offender_id)
    end

    it 'does not include extra data keys beyond before/after' do
      audit = AuditEvent.order(:created_at).last
      expect(audit.data.keys).to contain_exactly('before', 'after')
    end
  end

  describe 'with a non-offender-linked model (PomDetail)' do
    let!(:prison) { create(:prison) }
    let!(:pom_detail) { create(:pom_detail, prison: prison) }

    it 'sets nomis_offender_id to nil' do
      audit = AuditEvent.order(:created_at).last
      expect(audit.nomis_offender_id).to be_nil
    end

    it 'includes additional data from audit_additional_data' do
      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.data['nomis_staff_id']).to eq(pom_detail.nomis_staff_id)
        expect(audit.data['prison_code']).to eq(prison.code)
        expect(audit.data).to have_key('before')
        expect(audit.data).to have_key('after')
      end
    end
  end

  describe 'system_event flag' do
    let!(:prison) { create(:prison) }

    it 'is false when whodunnit is present' do
      create(:pom_detail, prison: prison)
      audit = AuditEvent.order(:created_at).last
      expect(audit.system_event).to be(false)
    end

    it 'is true when whodunnit is blank' do
      PaperTrail.request.whodunnit = nil
      create(:pom_detail, prison: prison)
      audit = AuditEvent.order(:created_at).last
      expect(audit.system_event).to be(true)
    end
  end

  describe 'excluded keys' do
    let!(:case_info) { create(:case_information, :manual_entry, tier: 'B', rosh_level: 'LOW', enhanced_resourcing: false) }

    it 'strips excluded keys from before and after' do
      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.data['before']).not_to have_key('id')
        expect(audit.data['before']).not_to have_key('nomis_offender_id')
        expect(audit.data['after']).not_to have_key('id')
        expect(audit.data['after']).not_to have_key('nomis_offender_id')
      end
    end
  end

  describe 'no-op when nothing changed' do
    let!(:prison) { create(:prison) }
    let!(:pom_detail) { create(:pom_detail, prison: prison) }

    it 'does not publish when save produces no changes' do
      expect { pom_detail.save! }.not_to change(AuditEvent, :count)
    end
  end

  describe 'on destroy' do
    let!(:case_info) { create(:case_information, :manual_entry, tier: 'B', rosh_level: 'LOW', enhanced_resourcing: false) }

    it 'publishes an audit event' do
      expect { case_info.destroy! }.to change(AuditEvent, :count).by(1)
    end

    it 'records the destroyed attributes as before and an empty after' do
      case_info.destroy!
      audit = AuditEvent.order(:created_at).last

      aggregate_failures do
        expect(audit.data['before']).not_to have_key('id')
        expect(audit.data['before']).not_to have_key('nomis_offender_id')
        expect(audit.data['before']['tier']).to eq('B')
        expect(audit.data['after']).to eq({})
      end
    end

    it 'sets nomis_offender_id from the destroyed record' do
      offender_id = case_info.nomis_offender_id
      case_info.destroy!
      audit = AuditEvent.order(:created_at).last
      expect(audit.nomis_offender_id).to eq(offender_id)
    end

    it "replaces the 'changed' tag with 'destroyed'" do
      case_info.destroy!
      audit = AuditEvent.order(:created_at).last

      aggregate_failures do
        expect(audit.tags).to include('destroyed')
        expect(audit.tags).not_to include('changed')
        expect(audit.tags).to include('record', 'case_information')
      end
    end
  end

  describe 'tags on create and update' do
    let!(:case_info) { create(:case_information, :manual_entry, tier: 'B', rosh_level: 'LOW', enhanced_resourcing: false) }

    it "uses 'created' tag on create" do
      audit = AuditEvent.order(:created_at).last
      expect(audit.tags).to include('created')
      expect(audit.tags).not_to include('changed')
      expect(audit.tags).not_to include('destroyed')
    end

    it "uses 'changed' tag on update" do
      case_info.update!(tier: 'C')
      audit = AuditEvent.order(:created_at).last
      expect(audit.tags).to include('changed')
      expect(audit.tags).not_to include('created')
      expect(audit.tags).not_to include('destroyed')
    end
  end

  describe '.without_audit_events' do
    let!(:prison) { create(:prison) }

    it 'suppresses audit events inside the block' do
      expect {
        described_class.without_audit_events do
          create(:pom_detail, prison:)
        end
      }.not_to change(AuditEvent, :count)
    end

    it 'restores audit event publishing after the block' do
      described_class.without_audit_events do
        create(:pom_detail, prison:)
      end

      expect { create(:pom_detail, prison:) }.to change(AuditEvent, :count).by(1)
    end
  end
end
