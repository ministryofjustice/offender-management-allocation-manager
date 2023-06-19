RSpec.describe 'Audit events' do
  describe 'UI' do
    before do
      allow_any_instance_of(Manage::AuditEventsController).to receive_messages(
        ensure_admin_user: nil,
        authenticate_user: nil,
        check_prison_access: nil,
        load_staff_member: nil,
        service_notifications: nil,
        load_roles: nil,
      )
    end

    it 'shows common information for each record', :aggregate_failures do
      FactoryBot.create :audit_event, :system,
                        nomis_offender_id: 'X1111XX',
                        tags: ['test', 'event1'],
                        data: { 'event_data' => '1' }
      visit manage_audit_events_path
      expect(page).to have_content 'X1111XX'
      expect(page).to have_content 'testevent1'
      expect(page).to have_content(:all, 'event_data')
    end
  end

  describe 'DB records' do
    it 'contain the govuk notify details for each emails' do
      TestOnlyMailer.with(to: 'test@example.org', template: 'test-template-x', personalisation: { 'test' => 'value' })
                    .test_mail.deliver_now
      expect(AuditEvent.first.data['govuk_notify_message']).to eq({
        'to' => ['test@example.org'],
        'template' => 'test-template-x',
        'personalisation' => { 'test' => 'value' }
      })
    end
  end
end
