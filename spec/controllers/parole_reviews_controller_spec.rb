# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParoleReviewsController, type: :controller do
  let(:prison) { create(:prison).code }
  let(:offender) { build(:mpc_offender, :with_persona, :robin_hoodwink) }
  let(:parole_review) { build(:parole_review) }

  before do
    stub_sso_data(prison)

    allow(OffenderService).to receive(:get_offender).and_return(offender)
    allow(ParoleReview).to receive(:find_by!).and_return(parole_review)
  end

  describe 'GET #edit' do
    it 'assigns the requested parole review as @parole_review' do
      get :edit, params: { prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id }
      expect(assigns(:parole_review)).to eq(parole_review)
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      let(:valid_params) { ActionController::Parameters.new(hearing_outcome_received_on: Time.zone.today.to_s).permit! }

      it 'updates the requested parole review' do
        expect(parole_review).to receive(:update).with(valid_params)
        patch :update, params: {
          prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id, parole_review: valid_params.to_h
        }
      end

      it 'enqueues the job and redirects to the offender' do
        expect(RecalculateHandoverDateJob).to receive(:perform_now).with(offender.offender_no)
        patch :update, params: {
          prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id, parole_review: valid_params
        }
        expect(response).to redirect_to(prison_prisoner_path(prison: prison, id: offender.offender_no))
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { ActionController::Parameters.new(hearing_outcome_received_on: nil).permit! }

      it 'does not enqueue the job and renders the edit template' do
        expect(RecalculateHandoverDateJob).not_to receive(:perform_now)
        patch :update, params: {
          prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id, parole_review: invalid_params.to_h
        }
        expect(response).to render_template(:edit)
      end
    end

    context 'when parole review is not found' do
      before do
        allow(ParoleReview).to receive(:find_by!).and_call_original
      end

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          patch :update, params: {
            prison_id: prison, prisoner_id: offender.offender_no, id: 'invalid', parole_review: {}
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
