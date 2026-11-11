RSpec.describe 'Audit events' do
  describe 'UI' do
    before do
      allow_any_instance_of(Manage::AuditEventsController).to receive_messages(
        authenticate_user: nil,
        ensure_admin_user: nil,
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

    it 'submits a search and preserves the filters through pagination', aggregate_failures: true do
      FactoryBot.create_list :audit_event, 26, :system,
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

      click_link 'Next', match: :first
      expect(page).to have_current_path(search_manage_audit_events_path, ignore_query: true)
      expect(page).to have_content 'X1111XX'
      expect(page).not_to have_content 'X1111YY'
      expect(page).to have_field('tags', with: 'test tag1')

      click_link 'Reset filters'
      expect(page).to have_current_path(manage_audit_events_path)
      expect(page).to have_field('nomis_offender_id', with: '')
      expect(page).to have_field('tags', with: '')
      expect(page).to have_field('whodunnit', with: '')
      expect(page).to have_content 'Most recent events'
      expect(page).to have_content 'X1111YY'
    end
  end
end
