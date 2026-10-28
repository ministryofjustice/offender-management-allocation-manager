# frozen_string_literal: true

RSpec.shared_context 'with HMPPS audit event capture' do
  let(:hmpps_audit_client) { instance_double(HmppsAudit::Client) }
  let(:hmpps_audit_events) { [] }

  before do
    allow(HmppsAudit::Client).to receive(:new).and_return(hmpps_audit_client)
    allow(hmpps_audit_client).to receive(:publish) { |**attributes| hmpps_audit_events << attributes }
  end
end
