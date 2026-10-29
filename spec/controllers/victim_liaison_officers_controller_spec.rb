# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VictimLiaisonOfficersController, type: :controller do
  include_context 'with HMPPS audit event capture'

  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:offender_record) { create(:offender, nomis_offender_id: offender_no) }
  let(:vlo) { create(:victim_liaison_officer, offender: offender_record) }

  before do
    stub_sso_data(prison.code)
    stub_offender(offender)
  end

  describe '#new' do
    it 'displays the new VLO details form and audits the prisoner viewed' do
      get :new, params: { prison_id: prison.code, prisoner_id: offender_no }

      expect(response).to have_http_status(:ok)
      expect(assigns(:vlo)).to be_a_new(VictimLiaisonOfficer)
      expect(hmpps_audit_events).to have_recorded_event('VIEW_NEW_VLO_DETAILS_FORM', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
    end
  end

  describe '#edit' do
    it 'displays the VLO details form and audits the prisoner viewed' do
      get :edit, params: { prison_id: prison.code, prisoner_id: offender_no, id: vlo.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:vlo)).to eq(vlo)
      expect(hmpps_audit_events).to have_recorded_event('VIEW_VLO_DETAILS_FORM', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
    end
  end

  describe '#delete' do
    it 'displays the removal confirmation and audits the prisoner viewed' do
      get :delete, params: { prison_id: prison.code, prisoner_id: offender_no, id: vlo.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:vlo)).to eq(vlo)
      expect(hmpps_audit_events).to have_recorded_event('VIEW_VLO_REMOVAL_CONFIRMATION', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
    end
  end
end
