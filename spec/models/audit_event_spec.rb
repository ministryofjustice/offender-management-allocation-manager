RSpec.describe AuditEvent do
  let(:attributes) { FactoryBot.attributes_for(:audit_event, :system, tags: %w[tag1 tag2]).except(:published_at) }

  it 'can have username and user_human_name if system_event is false', :aggregate_failures do
    event = FactoryBot.create :audit_event, :user
    expect(event.system_event?).to eq false
    expect(event.username).not_to be_blank
    expect(event.user_human_name).not_to be_blank
  end

  it 'cannot have username or user_human_name if system_event is true', :aggregate_failures do
    expect { FactoryBot.create :audit_event, :system, username: 'test' }
      .to raise_error(/PG::CheckViolation: ERROR:.+audit_events.+system_event_cannot_have_user_details/)
    expect { FactoryBot.create :audit_event, :system, user_human_name: 'test' }
      .to raise_error(/PG::CheckViolation: ERROR:.+audit_events.+system_event_cannot_have_user_details/)
  end

  describe 'when published' do
    it 'creates a record' do
      expect { described_class.publish(**attributes) }
        .to change(described_class, :count).by(1)
    end

    it 'logs the audit event to the system/Rails logger', :aggregate_failures do
      line = ''
      allow(Rails.logger).to receive(:info) { |data| line.replace(data) }
      record = described_class.publish(**attributes)

      expect(line).to match('event=audit_event_published')
      expect(line).to match(record.nomis_offender_id)
      expect(line).to match(record.id)
      expect(line).to match(/tag1.+tag2/)
    end

    it 'saves a published_at date' do
      record = described_class.publish(**attributes)
      expect(record.published_at).to be_within(1.second).of(Time.zone.now.utc)
    end
  end

  describe '::tags' do
    it 'filters by tag', :aggregate_failures do
      r1 = FactoryBot.create :audit_event, :system, nomis_offender_id: 'X1111XX', tags: ['test', 'tag1'], data: {}
      r2 = FactoryBot.create :audit_event, :system, nomis_offender_id: 'X1111YY', tags: ['test', 'tag1'], data: {}
      rx = FactoryBot.create :audit_event, :system, nomis_offender_id: 'X1111ZZ', tags: ['test', 'tag2'], data: {}

      expect(described_class.tags('test')).to match_array([r1, r2, rx])
      expect(described_class.tags('test', 'tag1')).to match_array([r1, r2])
    end

    it 'lowercases tags before search' do
      r1 = FactoryBot.create :audit_event, :system, nomis_offender_id: 'X1111XX', tags: ['test', 'tag1'], data: {}
      expect(described_class.tags('tEst')).to eq([r1])
    end
  end
end
