# frozen_string_literal: true

class ParoleReviewsController < PrisonsApplicationController
  before_action :load_offender

  def edit
    @parole_review = ParoleReview.find_by(review_id: params[:id])
  end

  def update
    @parole_review = ParoleReview.find_by(review_id: params[:id])
    @parole_review.update(parole_review_params)

    if @parole_review.valid?(:manual_update)
      RecalculateHandoverDateJob.perform_now(@offender.offender_no)
      redirect_to prison_prisoner_path(prison: @prison, id: @offender.offender_no)
    else
      render 'edit'
    end
  end

private

  def load_offender
    @offender = OffenderService.get_offender(params[:prisoner_id])
  end

  def parole_review_params
    params.require(:parole_review).permit(:hearing_outcome_received_on)
  end
end
