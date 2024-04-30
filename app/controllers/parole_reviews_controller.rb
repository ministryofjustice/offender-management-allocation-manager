# frozen_string_literal: true

class ParoleReviewsController < PrisonsApplicationController
  before_action :load_offender

  def edit
    @parole_review = ParoleReview.find_by(review_id: params[:id])
  end

  def update
    @parole_review = ParoleReview.find_by(review_id: params[:id])
    hearing_outcome_received_date = validate_date(params)
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

  def validate_date(params)
    if params['parole_review'].values.all?(&:blank?)
      @parole_review.errors.add('hearing_outcome_received', 'Enter the date the hearing outcome was confirmed')
    elsif params['parole_review'].values.any?(&:blank?)
      @parole_review.errors.add('hearing_outcome_received', 'Enter the full date the hearing outcome was confirmed')
    end

    return unless @parole_review.errors.empty?

    begin
      date = Date.new(params['parole_review']['hearing_outcome_received(1i)'].to_i, params['parole_review']['hearing_outcome_received(2i)'].to_i, params['parole_review']['hearing_outcome_received(3i)'].to_i)
    rescue StandardError
      @parole_review.errors.add('hearing_outcome_received', 'The date the hearing outcome was confirmed must be a real date')
    end

    return unless date

    if date.future?
      @parole_review.errors.add('hearing_outcome_received', 'The date the hearing outcome was confirmed must be in the past')
    end

    date
  end
end
