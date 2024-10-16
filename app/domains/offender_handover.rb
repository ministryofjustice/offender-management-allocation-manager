class OffenderHandover < SimpleDelegator
  COM_NO_HANDOVER_DATE = CalculatedHandoverDate.new(
    responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
    reason: :com_responsibility)

  def as_calculated_handover_date
    if indeterminate_sentence? && sentences.sentenced_to_additional_future_isp?
      pom_only(:additional_isp)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && recalled? && mappa_level.in?([nil, 0, 1])
      pom_with_com(:recall_thd_over_12_months)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && parole_outcome_not_release? && mappa_level.in?([2, 3])
      com(:parole_mappa_2_3)
    elsif indeterminate_sentence? && thd_12_or_more_months_from_now? && parole_outcome_not_release?
      pom_with_com(:thd_over_12_months)
    elsif recalled?
      com(:recall_case)
    elsif immigration_case?
      com(:immigration_case)
    elsif !earliest_release_for_handover
      pom_only(:release_date_unknown)
    else
      general_rules
    end
  end

private

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

  def pom_only(reason = nil) = CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::CUSTODY_ONLY, reason:)
  def pom_with_com(reason = nil) = CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::CUSTODY_WITH_COM, reason:)
  def com(reason = nil) = CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE, reason:)
end
