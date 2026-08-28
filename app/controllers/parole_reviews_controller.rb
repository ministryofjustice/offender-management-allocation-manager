# frozen_string_literal: true

class ParoleReviewsController < PrisonsApplicationController
  before_action :load_offender, :load_parole_review_record, :ensure_editable_parole_review

  def edit; end

  def update
    @parole_review.assign_attributes(parole_review_params)

    if @parole_review.save(context: :manual_update)
      redirect_to helpers.prisoner_path_for_role(@prison, @offender)
    else
      render :edit
    end
  end

private

  def load_offender
    @offender = get_offender_or_404(params[:prisoner_id])
  end

  def load_parole_review_record
    @parole_review = ParoleReview.find_by!(review_id: params[:id], nomis_offender_id: @offender.offender_no)
  end

  def ensure_editable_parole_review
    return if @parole_review.hearing_outcome_received_on.blank? && !@parole_review.no_hearing_outcome?

    redirect_to '/404'
  end

  def parole_review_params
    params.require(:parole_review).permit(:hearing_outcome_received_on)
  end
end
