# frozen_string_literal: true

# Used to view and edit individual parole applications (records) for individual offenders
class ParoleRecordsController < PrisonsApplicationController
  before_action :load_offender

  def edit
    @parole_record = ParoleRecord.find_by(review_id: params[:id])
  end

  def update
    @parole_record = ParoleRecord.find_by(review_id: params[:id])
    hearing_outcome_received_date = validate_date(params)
    if @parole_record.errors.empty? && @parole_record.update(hearing_outcome_received: hearing_outcome_received_date)
      RecalculateHandoverDateJob.perform_now(@offender.offender_no)
      redirect_to prison_prisoner_path(prison_id: @offender.prison_id, id: @offender.offender_no)
    else
      render 'edit'
    end
  end

private

  def load_offender
    @offender = OffenderService.get_offender(params[:prisoner_id])
  end

  def validate_date(params)
    if params['parole_record'].values.all?(&:blank?)
      @parole_record.errors.add('hearing_outcome_received', 'Enter the date the hearing outcome was confirmed')
    elsif params['parole_record'].values.any?(&:blank?)
      @parole_record.errors.add('hearing_outcome_received', 'Enter the full date the hearing outcome was confirmed')
    end

    return unless @parole_record.errors.empty?

    begin
      date = Date.new(params['parole_record']['hearing_outcome_received(1i)'].to_i, params['parole_record']['hearing_outcome_received(2i)'].to_i, params['parole_record']['hearing_outcome_received(3i)'].to_i)
    rescue StandardError
      @parole_record.errors.add('hearing_outcome_received', 'The date the hearing outcome was confirmed must be a real date')
    end

    return unless date

    if date.future?
      @parole_record.errors.add('hearing_outcome_received', 'The date the hearing outcome was confirmed must be in the past')
    end

    date
  end
end
