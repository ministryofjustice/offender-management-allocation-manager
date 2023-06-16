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
end
