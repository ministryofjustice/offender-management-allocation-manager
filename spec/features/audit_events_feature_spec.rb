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

    it 'shows common information for each record' do
      FactoryBot.create :audit_event, :system,
                        nomis_offender_id: 'X1111XX',
                        tags: ['test', 'event1'],
                        data: { 'event_data' => '1' }
      visit manage_audit_events_path
      expect(page).to have_content 'X1111XX'
      expect(page).to have_content 'testevent1'
      expect(page).to have_content(:all, 'event_data')
    end

    it 'can filter by tag', aggregate_failures: true do
      FactoryBot.create_list :audit_event, 3, :system,
                             nomis_offender_id: 'X1111XX',
                             tags: ['test', 'tag1'],
                             data: {}
      FactoryBot.create :audit_event, :system,
                        nomis_offender_id: 'X1111YY',
                        tags: ['test', 'tag2'],
                        data: {}

      visit manage_audit_events_path
      fill_in 'tags', with: " test, tag1\n"
      click_on 'Search'
      expect(page).to have_content 'X1111XX'
      expect(page).not_to have_content 'X1111YY'
      expect(page).to have_content 'tag1'
      expect(page).not_to have_content 'tag2'
    end
  end

  describe 'when delivering email' do
    let(:test_email) do
      TestOnlyMailer.with(
        to: 'test@example.org', template: 'test-template-x', personalisation: { 'test' => 'value' }
      ).test_mail
    end

    let(:audit_event) { AuditEvent.first }

    before do
      test_email.deliver_now
    end

    it 'is tagged and contains the govuk notify details' do
      expect(audit_event.tags).to eq(%w[email test_only test_mail perform_deliveries_false])

      expect(audit_event.data['govuk_notify_message']).to eq({
        'to' => ['test@example.org'],
        'template' => 'test-template-x',
        'personalisation' => { 'test' => 'value' }
      })
    end
  end
end
