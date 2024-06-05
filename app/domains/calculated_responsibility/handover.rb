class CalculatedResponsibility::Handover
  def initialize(offender)
    @offender = offender
  end

  delegate :start_date, :date, :reason, :responsibility, to: :calculated_values

private

  attr_reader :offender

  def calculated_values
    @calculated_values ||= begin
      date, reason = Handover::HandoverCalculation.calculate_handover_date(
        sentence_start_date: offender.sentence_start_date,
        earliest_release_date: offender.earliest_release&.date,
        is_early_allocation: offender.early_allocation?,
        is_indeterminate: offender.indeterminate_sentence?,
        in_open_conditions: offender.in_open_conditions?,
        is_determinate_parole: offender.determinate_parole?,
        is_recall: offender.recalled?
      )

      start_date = Handover::HandoverCalculation.calculate_handover_start_date(
        handover_date: date,
        category_active_since_date: offender.category_active_since,
        prison_arrival_date: offender.prison_arrival_date,
        is_indeterminate: offender.indeterminate_sentence?,
        open_prison_rules_apply: offender.open_prison_rules_apply?,
        in_womens_prison: offender.in_womens_prison?,
      )

      responsibility = Handover::HandoverCalculation.calculate_responsibility(
        handover_date: date,
        handover_start_date: start_date
      )

      OpenStruct.new(date:, reason:, start_date:, responsibility:)
    end
  end
end
