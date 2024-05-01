# frozen_string_literal: true

class ParoleReviewsController < PrisonsApplicationController
  before_action :load_offender

  def edit
    @parole_review = ParoleReview.find_by(review_id: params[:id])
  end

  def update
    @parole_review = ParoleReview.find_by(review_id: params[:id])
    hearing_outcome_received_date = @parole_review.validate_hearing_outcome_date(params['parole_review'])
    if @parole_review.errors.empty? && @parole_review.update(hearing_outcome_received_on: hearing_outcome_received_date)
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
end
