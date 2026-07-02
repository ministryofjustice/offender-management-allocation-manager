# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomDetail, type: :model do
  let!(:prison) { create(:prison) }

  it { is_expected.to validate_presence_of(:nomis_staff_id) }
  it { expect(create(:pom_detail, prison: prison)).to validate_uniqueness_of(:nomis_staff_id).scoped_to(:prison_code) }
  it { is_expected.to validate_presence_of(:working_pattern).with_message('Select full time or part time') }
  it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.values) }

  describe '#hours_per_week=' do
    it 'converts hours to working pattern ratio' do
      subject.hours_per_week = 30
      expect(subject.working_pattern).to eq(0.8)
    end

    it 'converts full time hours to 1.0' do
      subject.hours_per_week = 37.5
      expect(subject.working_pattern).to eq(1.0)
    end

    it 'caps working pattern to 1.0 for hours greater than full time' do
      subject.hours_per_week = 40
      expect(subject.working_pattern).to eq(1.0)
    end
  end

  describe '#hours_per_week' do
    it 'converts working pattern to hours' do
      subject.working_pattern = 0.8
      expect(subject.hours_per_week).to eq(30.0)
    end

    it 'returns full time hours for full time pattern' do
      subject.working_pattern = 1.0
      expect(subject.hours_per_week).to eq(37.5)
    end
  end

  describe '#has_primary_allocations?' do
    let(:nomis_staff_id) { 1234 }
    let(:pom_detail) { create(:pom_detail, nomis_staff_id:, prison:) }
    let(:offender) { instance_double(MpcOffender, offender_no: 'A1234BC', active_allocation: allocation) }
    let(:allocation) { instance_double(AllocationHistory, primary_pom_nomis_id: nomis_staff_id) }

    before do
      allow(prison).to receive(:allocated).and_return([offender])
      allow(AllocationHistory).to receive(:active_pom_allocations).with(nomis_staff_id, prison.code).and_return(double(pluck: ['A1234BC']))
    end

    it 'returns true if there is a primary allocation for this POM' do
      expect(pom_detail.has_primary_allocations?).to be true
    end

    it 'returns false if there are no primary allocations for this POM' do
      allow(allocation).to receive(:primary_pom_nomis_id).and_return(9999)
      expect(pom_detail.has_primary_allocations?).to be false
    end

    it 'returns false if there are no allocations' do
      allow(AllocationHistory).to receive(:active_pom_allocations).with(nomis_staff_id, prison.code).and_return(double(pluck: []))
      expect(pom_detail.has_primary_allocations?).to be false
    end
  end

  describe '#save_audit_event' do
    before do
      PaperTrail.request.whodunnit = 'SPO_USER'
    end

    after do
      PaperTrail.request.whodunnit = nil
    end

    it 'publishes an audit event with correct tags and additional data' do
      pom_detail = create(:pom_detail, prison: prison)

      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.nomis_offender_id).to be_nil
        expect(audit.tags).to eq(%w[record pom_detail changed])
        expect(audit.data['nomis_staff_id']).to eq(pom_detail.nomis_staff_id)
        expect(audit.data['prison_code']).to eq(prison.code)
      end
    end

    it 'records before and after changes on update' do
      pom_detail = create(:pom_detail, prison: prison, status: 'active', working_pattern: 1.0)
      last_audit = AuditEvent.order(:created_at).last

      pom_detail.update!(status: 'inactive', working_pattern: 0.8)

      audit = AuditEvent.where.not(id: last_audit.id).order(:created_at).last
      aggregate_failures do
        expect(audit.data['before']).to include('status' => 'active', 'working_pattern' => 1.0)
        expect(audit.data['after']).to include('status' => 'inactive', 'working_pattern' => 0.8)
      end
    end
  end
end
