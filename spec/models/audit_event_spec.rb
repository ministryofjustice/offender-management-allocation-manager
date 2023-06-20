RSpec.describe AuditEvent do
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
