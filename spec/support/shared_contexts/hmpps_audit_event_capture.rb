# frozen_string_literal: true

RSpec.shared_context 'with HMPPS audit event capture' do
  let(:hmpps_audit_client) { instance_double(HmppsAudit::Client) }
  let(:hmpps_audit_events) { [] }
  let(:hmpps_auth_audit_events) { [] }

  before do
    allow(HmppsAudit).to receive(:client).and_return(hmpps_audit_client)

    # Keep authentication during feature setup separate from the action under test
    allow(hmpps_audit_client).to receive(:publish) do |**attributes|
      events = attributes.fetch(:what).start_with?('AUTH_') ? hmpps_auth_audit_events : hmpps_audit_events
      events << attributes
    end
  end
end
