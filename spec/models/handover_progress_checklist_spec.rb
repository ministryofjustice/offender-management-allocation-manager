RSpec.describe HandoverProgressChecklist do
  subject(:checklist) { described_class.new offender: FactoryBot.build(:offender) }

  let(:cutoff_date) { Rails.configuration.x.simplified_handover_cutoff_date }

  before do
    allow(checklist.offender).to receive_messages(handover_type: 'enhanced')
  end

  describe '.permitted_task_fields' do
    context 'with enhanced handover' do
      it 'returns 3-task fields when handover_date is before the cutoff' do
        expect(described_class.permitted_task_fields(
                 handover_type: 'enhanced',
                 handover_date: cutoff_date - 1.day,
               )).to eq(%i[reviewed_oasys contacted_com attended_handover_meeting])
      end

      it 'returns 2-task fields when handover_date is on or after the cutoff' do
        expect(described_class.permitted_task_fields(
                 handover_type: 'enhanced',
                 handover_date: cutoff_date,
               )).to eq(%i[reviewed_oasys contacted_com])
      end

      it 'returns 3-task fields when handover_date is nil (default)' do
        expect(described_class.permitted_task_fields(
                 handover_type: 'enhanced',
                 handover_date: nil,
               )).to eq(%i[reviewed_oasys contacted_com attended_handover_meeting])
      end

      it 'returns 3-task fields when simplified_enhanced_handover feature flag is disabled' do
        stub_feature_flag(:simplified_enhanced_handover, enabled: false)

        expect(described_class.permitted_task_fields(
                 handover_type: 'enhanced',
                 handover_date: cutoff_date + 1.day,
               )).to eq(%i[reviewed_oasys contacted_com attended_handover_meeting])
      end
    end

    context 'with standard handover' do
      it 'returns standard fields regardless of dates' do
        expect(described_class.permitted_task_fields(
                 handover_type: 'standard',
                 handover_date: cutoff_date + 1.day,
               )).to eq(%i[contacted_com sent_handover_report])
      end
    end
  end

  context 'when enhanced handover date is before the cutoff (3-task version)' do
    before do
      allow(checklist.offender).to receive_messages(handover_date: cutoff_date - 1.day)
    end

    describe '#progress_data' do
      it 'returns completed and total enhanced handover tasks' do
        checklist.attributes = {
          reviewed_oasys: false,
          contacted_com: false,
          sent_handover_report: true, # ignored
          attended_handover_meeting: true,
        }

        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 3)
      end

      it 'returns completed and total standard handover tasks' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = {
          reviewed_oasys: true, # ignored
          contacted_com: false,
          sent_handover_report: true,
        }

        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end

    describe '#task_completion_data' do
      it 'returns enhanced completion data for enhanced handovers' do
        checklist.attributes = {
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: true,
          sent_handover_report: true, # ignored
        }

        expect(checklist.task_completion_data).to eq(
          'reviewed_oasys' => false,
          'contacted_com' => false,
          'attended_handover_meeting' => true,
        )
      end

      it 'returns standard completion data for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = {
          reviewed_oasys: true, # ignored
          contacted_com: false,
          sent_handover_report: true,
        }

        expect(checklist.task_completion_data).to eq(
          'contacted_com' => false,
          'sent_handover_report' => true,
        )
      end
    end

    describe '#handover_progress_complete?' do
      it 'is false when any enhanced handover task is incomplete' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(false)
      end

      it 'is true when all enhanced handover tasks are complete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(true)
      end
    end
  end

  context 'when enhanced handover date is on or after the cutoff (2-task version)' do
    before do
      allow(checklist.offender).to receive_messages(handover_date: cutoff_date)
    end

    describe '#progress_data' do
      it 'counts only reviewed_oasys and contacted_com for enhanced handovers' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end

      it 'still counts standard tasks for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = { contacted_com: false, sent_handover_report: true }
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end

    describe '#task_completion_data' do
      it 'returns only reviewed_oasys and contacted_com for enhanced handovers' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.task_completion_data).to eq('reviewed_oasys' => false, 'contacted_com' => true)
      end

      it 'returns standard fields for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = { contacted_com: false, sent_handover_report: true }
        expect(checklist.task_completion_data).to eq('contacted_com' => false, 'sent_handover_report' => true)
      end
    end

    describe '#handover_progress_complete?' do
      it 'is false when any simplified enhanced task is incomplete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: false, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(false)
      end

      it 'is true when both simplified enhanced tasks are complete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: false }
        expect(checklist.handover_progress_complete?).to be(true)
      end
    end
  end

  describe '#save_audit_event' do
    let(:offender) { create(:offender) }

    before do
      PaperTrail.request.whodunnit = 'POM_USER'
      allow_any_instance_of(described_class).to receive(:handover_type).and_return('enhanced')
    end

    after do
      PaperTrail.request.whodunnit = nil
    end

    it 'publishes an audit event with correct tags and offender id on create' do
      checklist = described_class.create!(offender: offender, reviewed_oasys: true, contacted_com: true)

      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.nomis_offender_id).to eq(checklist.nomis_offender_id)
        expect(audit.tags).to eq(%w[record handover_progress_checklist changed])
      end
    end

    it 'records before and after changes on update' do
      checklist = described_class.create!(offender: offender)
      last_audit = AuditEvent.order(:created_at).last

      checklist.update!(contacted_com: true)

      audit = AuditEvent.where.not(id: last_audit.id).order(:created_at).last
      aggregate_failures do
        expect(audit.data['before']).to include('contacted_com' => false)
        expect(audit.data['after']).to include('contacted_com' => true)
      end
    end
  end
end
