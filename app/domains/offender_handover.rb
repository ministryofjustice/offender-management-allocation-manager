class OffenderHandover < SimpleDelegator
  def as_calculated_handover_date
    if indeterminate_sentence? && sentences.sentenced_to_additional_future_isp?
      pom_only(reason: :additional_isp)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && recalled? && mappa_level.in?([nil, 0, 1])
      pom_with_com(reason: :recall_thd_over_12_months)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && parole_outcome_not_release? && mappa_level.in?([2, 3])
      com(reason: :parole_mappa_2_3)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && parole_outcome_not_release?
      pom_with_com(reason: :thd_over_12_months)
    elsif recalled?
      com(reason: :recall_case)
    elsif immigration_case?
      com(reason: :immigration_case)
    elsif !earliest_release_for_handover
      pom_only(reason: :release_date_unknown)
    else
      general_rules
    end
  end

private

  delegate :pom_only, :pom_with_com, :com, to: CalculatedHandoverDate

  def general_rules
    handover_date, reason = Handover::HandoverCalculation.calculate_handover_date(
      sentence_start_date:,
      earliest_release_date: earliest_release_for_handover&.date,
      is_early_allocation: early_allocation?,
      is_indeterminate: indeterminate_sentence?,
      in_open_conditions: in_open_conditions?,
      is_determinate_parole: determinate_parole?
    )

    start_date = Handover::HandoverCalculation.calculate_handover_start_date(
      handover_date:,
      category_active_since_date: category_active_since,
      prison_arrival_date:,
      is_indeterminate: indeterminate_sentence?,
      open_prison_rules_apply: open_prison_rules_apply?,
      in_womens_prison: in_womens_prison?,
    )

    responsibility = Handover::HandoverCalculation.calculate_responsibility(
      handover_date:,
      handover_start_date: start_date
    )

    CalculatedHandoverDate.new(responsibility:, handover_date:, start_date:, reason:)
  end
end
