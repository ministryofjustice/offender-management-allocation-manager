# frozen_string_literal: true

RSpec.shared_context 'with audit event capture' do
  let(:audit_client) { instance_double(HmppsAudit::Client) }
  let(:audit_events) { [] }

  before do
    allow(HmppsAudit::Client).to receive(:new).and_return(audit_client)
    allow(audit_client).to receive(:publish) { |**attributes| audit_events << attributes }
  end
end
