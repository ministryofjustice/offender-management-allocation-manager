# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmppsAudit do
  let(:client) { instance_double(HmppsAudit::Client, publish: nil) }
  let(:attributes) do
    {
      what: 'AUTH_USER_SIGN_IN_SUCCESS',
      who: 'test-user',
      subject_type: 'NOT_APPLICABLE',
      correlation_id: 'request-id'
    }
  end

  before do
    allow(described_class).to receive(:client).and_return(client)
  end

  it 'shares one client across threads' do
    allow(described_class).to receive(:client).and_call_original

    clients = Array.new(10) { Thread.new { described_class.client } }.map(&:value)

    expect(clients.first).to be_a(HmppsAudit::Client)
    expect(clients).to all(be(clients.first))
  end

  it 'publishes a single event through the audit client' do
    described_class.publish(**attributes)

    expect(client).to have_received(:publish).with(**attributes).once
  end

  it 'does not publish when auditing is disabled' do
    stub_feature_flag(:hmpps_audit, enabled: false)

    described_class.publish(**attributes)

    expect(client).not_to have_received(:publish)
  end

  it 'reports delivery errors without interrupting the caller' do
    error = IOError.new('Delivery failed')
    allow(client).to receive(:publish).and_raise(error)
    allow(Rails.error).to receive(:report)

    expect { described_class.publish(**attributes) }.not_to raise_error
    expect(Rails.error).to have_received(:report).with(
      error, handled: true, severity: :error, source: 'hmpps_audit',
             context: { what: 'AUTH_USER_SIGN_IN_SUCCESS', correlation_id: 'request-id' }
    )
  end
end
