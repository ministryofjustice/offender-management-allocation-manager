require 'rails_helper'

RSpec.describe PushHandoverDatesToDeliusJob, type: :job do
  let(:nomis_offender) { build(:nomis_offender) }
  let(:offender_no) { nomis_offender.fetch(:offenderNo) }

  before do
    stub_auth_token
    stub_offender(nomis_offender)
    create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS')
    allow(Nomis::Elite2::CommunityApi).to receive(:set_handover_dates)
  end

  it "pushes the offender's handover dates to the Community API" do
    offender = OffenderService.get_offender(offender_no)

    described_class.perform_now(offender_no)
    expect(Nomis::Elite2::CommunityApi).to have_received(:set_handover_dates).
      with(offender_no: offender_no,
           handover_start_date: offender.handover_start_date,
           responsibility_handover_date: offender.responsibility_handover_date,
      )
  end
end
