# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseInformationController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:offenderNo) }

  before do
    stub_signed_in_pom(prison, 1, 'alice')
    stub_pom_emails(1, [])
    stub_offender(offender)
  end

  describe '#create' do
    let(:team) { create(:team) }

    it 'creates a record and sends an email' do
      expect(PomMailer).to receive(:manual_case_info_update).and_call_original

      expect {
        post :create, params: { prison_id: prison,
                                case_information: {
                                  nomis_offender_id: offender_no,
                                  probation_service: 'England',
                                  tier: 'A',
                                  case_allocation: 'NPS',
                                  team_id: team.id
                                },
        }
      }.to change(CaseInformation, :count).by(1)

      expect(response).to redirect_to(prison_summary_pending_path(prison))
    end
  end
end
