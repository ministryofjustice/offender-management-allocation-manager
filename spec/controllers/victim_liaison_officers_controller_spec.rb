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
      expect(hmpps_audit_events.first[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s })
      expect(hmpps_audit_events.last[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s }, 'entityId' => vlo.id)
    end
  end

  describe '#delete' do
    it 'displays the removal confirmation' do
      get :delete, params: { prison_id: prison.code, prisoner_id: offender_no, id: vlo.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:vlo)).to eq(vlo)
      expect(hmpps_audit_events).to be_empty
    end
  end

  describe '#create' do
    it 'creates the VLO and audits success despite redirecting' do
      expect {
        post :create, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          victim_liaison_officer: { first_name: 'Jane', last_name: 'Smith', email: 'jane@example.com' }
        }
      }.to change(VictimLiaisonOfficer, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(hmpps_audit_events).to have_recorded_event('CREATE_VLO_DETAILS', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
      expect(hmpps_audit_events.last[:details]).to eq('entityId' => assigns(:vlo).id)
    end

    it 'audits validation failure without creating a VLO' do
      expect {
        post :create, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          victim_liaison_officer: { first_name: '', last_name: '', email: '' }
        }
      }.not_to change(VictimLiaisonOfficer, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
      expect(hmpps_audit_events).to have_recorded_event('CREATE_VLO_DETAILS', outcome: 'FAILURE', subject_id: offender_no)
      expect(hmpps_audit_events.last[:details]).to eq('failureReason' => 'Request failed validation')
    end
  end

  describe '#update' do
    it 'updates the VLO and audits success despite redirecting' do
      patch :update, params: {
        prison_id: prison.code,
        prisoner_id: offender_no,
        id: vlo.id,
        victim_liaison_officer: { first_name: 'Updated' }
      }

      expect(vlo.reload.first_name).to eq('Updated')
      expect(response).to redirect_to(root_path)
      expect(hmpps_audit_events).to have_recorded_event('EDIT_VLO_DETAILS', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
      expect(hmpps_audit_events.first[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s })
      expect(hmpps_audit_events.last[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s }, 'entityId' => vlo.id)
    end

    it 'audits validation failure without changing the VLO' do
      original_email = vlo.email
      patch :update, params: {
        prison_id: prison.code,
        prisoner_id: offender_no,
        id: vlo.id,
        victim_liaison_officer: { email: '' }
      }

      expect(vlo.reload.email).to eq(original_email)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(hmpps_audit_events).to have_recorded_event('EDIT_VLO_DETAILS', outcome: 'FAILURE', subject_id: offender_no)
      expect(hmpps_audit_events.last[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s }, 'entityId' => vlo.id, 'failureReason' => 'Request failed validation')
    end
  end

  describe '#destroy' do
    it 'deletes the VLO and audits success when confirmed' do
      vlo

      expect {
        delete :destroy, params: { prison_id: prison.code, prisoner_id: offender_no, id: vlo.id, delete_confirm: 'yes' }
      }.to change(VictimLiaisonOfficer, :count).by(-1)

      expect(response).to redirect_to(root_path)
      expect(hmpps_audit_events).to have_recorded_event('DELETE_VLO_DETAILS', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
      expect(hmpps_audit_events.first[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s })
      expect(hmpps_audit_events.last[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s }, 'entityId' => vlo.id)
    end

    it 'keeps the VLO and audits failure when deletion is not confirmed' do
      vlo

      expect {
        delete :destroy, params: { prison_id: prison.code, prisoner_id: offender_no, id: vlo.id, delete_confirm: 'no' }
      }.not_to change(VictimLiaisonOfficer, :count)

      expect(response).to redirect_to(root_path)
      expect(hmpps_audit_events).to have_recorded_event('DELETE_VLO_DETAILS', outcome: 'FAILURE', subject_id: offender_no)
      expect(hmpps_audit_events.last[:details]).to eq('queryParams' => { 'id' => vlo.id.to_s }, 'entityId' => vlo.id, 'failureReason' => 'User cancelled the action')
    end
  end
end
