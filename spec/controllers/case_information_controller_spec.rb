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

  describe '#update' do
    let(:team) { create(:team) }

    let(:params) {
      { prison_id: prison,
        nomis_offender_id: offender_no,
        form: 'probation_data',
        case_information: {
          nomis_offender_id: offender_no,
          probation_service: 'England',
          tier: 'A',
          case_allocation: 'NPS',
          team_id: team.id
        }
      }
    }

    it 'creates a record and sends an email' do
      expect(PomMailer).to receive(:manual_case_info_update).and_call_original

      expect {
        put :update, params: params
      }.to change(CaseInformation, :count).by(1)

      expect(response).to redirect_to(prison_summary_pending_path(prison))
    end

    context 'when bad form data is submitted' do
      shared_examples 'invalid form submission' do
        it 'responds with "400 Bad Request" HTTP status code' do
          put :update, params: params
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to eq('Invalid form submission')
        end
      end

      context 'when params[:form] is missing' do
        before { params.delete(:form) }

        include_examples 'invalid form submission'
      end

      context 'when params[:form] is not "probation_service" or "probation_data"' do
        before { params[:form] = 'invalid_form_name' }

        include_examples 'invalid form submission'
      end
    end
  end
end
