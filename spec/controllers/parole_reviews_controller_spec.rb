# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParoleReviewsController, type: :controller do
  let(:prison) { create(:prison).code }
  let(:offender) { build(:mpc_offender, :with_persona, :robin_hoodwink) }
  let(:parole_review) { build(:parole_review, :pom_task) }

  before do
    stub_sso_data(prison)

    allow(OffenderService).to receive(:get_offender).and_return(offender)
    allow(ParoleReview).to receive(:find_by!).and_return(parole_review)
    allow(parole_review).to receive(:assign_attributes)
    allow(parole_review).to receive(:save).with(context: :manual_update).and_return(true)
  end

  describe 'GET #edit' do
    it 'assigns the requested parole review as @parole_review' do
      get :edit, params: { prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id }
      expect(assigns(:parole_review)).to eq(parole_review)
    end

    it 'scopes the lookup by review_id and prisoner NOMIS ID' do
      expect(ParoleReview).to receive(:find_by!).with(
        review_id: parole_review.review_id.to_s,
        nomis_offender_id: offender.offender_no,
      ).and_return(parole_review)

      get :edit, params: { prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id }
    end

    it 'redirects to 404 when the review is not editable' do
      parole_review.hearing_outcome_received_on = 1.day.ago

      get :edit, params: { prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id }

      expect(response).to redirect_to('/404')
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      let(:valid_params) { ActionController::Parameters.new(hearing_outcome_received_on: Time.zone.today.to_s).permit! }

      it 'assigns attributes and saves using manual_update validation context' do
        expect(parole_review).to receive(:assign_attributes).with(valid_params)
        expect(parole_review).to receive(:save).with(context: :manual_update).and_return(true)
        patch :update, params: {
          prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id, parole_review: valid_params.to_h
        }
      end

      it 'enqueues the job and redirects to the offender' do
        expect(RecalculateHandoverDateJob).to receive(:perform_now).with(offender.offender_no, trigger_method: 'parole_review')
        expect(controller.helpers).to receive(:prisoner_path_for_role).with(instance_of(Prison), offender).and_return('/dynamic-prisoner-path')

        patch :update, params: {
          prison_id: prison, prisoner_id: offender.offender_no, id: parole_review.review_id, parole_review: valid_params
        }

        expect(response).to redirect_to('/dynamic-prisoner-path')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { ActionController::Parameters.new(hearing_outcome_received_on: nil).permit! }

      before do
        allow(parole_review).to receive(:save).with(context: :manual_update).and_return(false)
      end

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

    context 'when parole review is not editable' do
      before do
        parole_review.hearing_outcome_received_on = 1.day.ago
      end

      it 'redirects to 404' do
        patch :update, params: {
          prison_id: prison,
          prisoner_id: offender.offender_no,
          id: parole_review.review_id,
          parole_review: { hearing_outcome_received_on: Time.zone.today.to_s }
        }

        expect(response).to redirect_to('/404')
      end
    end
  end
end
