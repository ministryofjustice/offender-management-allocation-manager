require 'rails_helper'

RSpec.describe 'Prisoner case information HMPPS auditing', type: :feature do
  include_context 'with HMPPS audit event capture'

  let(:prison) { create(:prison, code: 'LEI') }
  let(:offender) { build(:stubbed_offender, nomis_id: 'G1234AB') }

  before do
    stub_signin_spo(build(:homd))
    stub_offenders_for_prison(prison.code, [offender])
  end

  it 'uses the real Rails request ID for both audit events' do
    visit prison_prisoner_path(prison.code, 'G1234AB')

    request_id = page.response_headers.transform_keys(&:downcase).fetch('x-request-id')
    expect(request_id).to be_present
    expect(hmpps_audit_events).to have_recorded_event('VIEW_CASE_INFORMATION', subject_id: 'G1234AB', correlation_id: request_id)
  end
end
