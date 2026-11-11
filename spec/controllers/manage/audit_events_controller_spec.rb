# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Manage::AuditEventsController, type: :controller do
  include_context 'with HMPPS audit event capture'

  before do
    stub_sso_data('LEI', roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  it 'shows the most recent events first, paginated, and audits the displayed records' do
    create(:audit_event, nomis_offender_id: 'C1234DE', created_at: 5.minutes.ago)
    older = create(:audit_event, nomis_offender_id: 'A1234BC', created_at: 4.minutes.ago)
    other_prisoner = create(:audit_event, nomis_offender_id: 'B1234CD', created_at: 3.minutes.ago)
    newer = create(:audit_event, nomis_offender_id: 'A1234BC', created_at: 2.minutes.ago)
    latest = create(:audit_event, nomis_offender_id: nil, created_at: 1.minute.ago)
    remaining = Array.new(21) { |index| create(:audit_event, created_at: 4.minutes.ago + (index + 1).seconds) }

    get :index, params: { page: '1' }

    expect(response).to be_successful
    expect(response).to render_template(:index)
    displayed = [latest, newer, other_prisoner, *remaining.reverse, older]
    expect(assigns(:audit_events).to_a).to eq(displayed)
    expect(hmpps_audit_events).to have_recorded_event('VIEW_AUDIT_EVENTS_SEARCH', subject_type: 'NOT_APPLICABLE', subject_id: nil)
    expect(hmpps_audit_events.first[:details]).to eq('queryParams' => { 'page' => '1' })
    expect(hmpps_audit_events.last[:details]).to eq(
      'queryParams' => { 'page' => '1' },
      'results' => { 'resultCount' => 25, 'returnedSubjectIds' => displayed.map(&:id) }
    )
  end

  it 'combines prisoner, user and tag filters and audits the search criteria' do
    matching = create(:audit_event, :user, nomis_offender_id: 'A1234BC', username: 'test-user', tags: %w[test selected])
    create(:audit_event, :user, nomis_offender_id: 'B1234CD', username: 'test-user', tags: %w[test selected])
    create(:audit_event, :user, nomis_offender_id: 'A1234BC', username: 'another-user', tags: %w[test selected])
    create(:audit_event, :user, nomis_offender_id: 'A1234BC', username: 'test-user', tags: %w[test other])

    get :search, params: { nomis_offender_id: ' A1234BC ', whodunnit: ' test-user ', tags: ' test, selected ' }

    expect(response).to be_successful
    expect(assigns(:audit_events).to_a).to eq([matching])
    expect(assigns(:tags)).to eq(%w[test selected])
    expect(response).to render_template(:index)
    expect(hmpps_audit_events).to have_recorded_event('SEARCH_AUDIT_EVENTS', subject_type: 'SEARCH_TERM', subject_id: nil)
    expect(hmpps_audit_events.last[:details]).to eq(
      'queryParams' => { 'nomisOffenderId' => 'A1234BC', 'whodunnit' => 'test-user', 'tags' => 'test, selected' },
      'results' => { 'resultCount' => 1, 'returnedSubjectIds' => [matching.id] }
    )
  end

  it 'filters system events case-insensitively rather than matching a username' do
    system_event = create(:audit_event, :system)
    without_prisoner = create(:audit_event, :system, nomis_offender_id: nil)
    create(:audit_event, :user, username: 'system')

    get :search, params: { whodunnit: ' SYSTEM ' }

    expect(response).to be_successful
    expect(assigns(:audit_events).to_a).to eq([without_prisoner, system_event])
    expect(hmpps_audit_events.last[:details]['results']).to eq(
      'resultCount' => 2, 'returnedSubjectIds' => [without_prisoner.id, system_event.id]
    )
  end

  it 'renders an empty list when no events match' do
    create(:audit_event, nomis_offender_id: 'A1234BC')

    get :search, params: { nomis_offender_id: 'B1234CD' }

    expect(response).to be_successful
    expect(assigns(:audit_events)).to be_empty
    expect(hmpps_audit_events.last[:details]['results']).to eq('resultCount' => 0, 'returnedSubjectIds' => [])
  end
end
