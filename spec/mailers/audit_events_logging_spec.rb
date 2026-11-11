# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email audit logging' do
  let(:test_email) do
    TestOnlyMailer.with(
      to: 'test@example.org', template: 'test-template-x', personalisation: { 'test' => 'value' }
    ).test_mail
  end

  it 'tags the audit event and records the GOV.UK Notify details' do
    test_email.deliver_now

    audit_event = AuditEvent.first
    expect(audit_event.tags).to eq(%w[email test_only test_mail perform_deliveries_false])
    expect(audit_event.data['govuk_notify_message']).to eq({
      'to' => ['test@example.org'],
      'template' => 'test-template-x',
      'personalisation' => { 'test' => 'value' }
    })
  end
end
