class OffenderHandover < SimpleDelegator
  COM_NO_HANDOVER_DATE = CalculatedHandoverDate.new(
    responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
    reason: :com_responsibility)

  def as_calculated_handover_date
    indeterminate_sentences || edge_cases || general_rules
  end

private

  def indeterminate_sentences
    return unless USE_PPUD_PAROLE_DATA && indeterminate_sentence?

    if parole_outcome_not_release? && thd_12_or_more_months_from_now? && mappa_level.in?([2, 3])
      CalculatedHandoverDate.new(responsibility: com, reason: :parole_mappa_2_3)
    elsif parole_outcome_not_release? && thd_12_or_more_months_from_now? && mappa_level.in?([nil, 1])
      CalculatedHandoverDate.new(responsibility: pom_with_com, reason: :thd_over_12_months)
    elsif sentenced_to_an_additional_isp?
      CalculatedHandoverDate.new(responsibility: pom_only, reason: :additional_isp)
    end
  end

  def edge_cases
    if recalled?
      CalculatedHandoverDate.new(responsibility: com, reason: :recall_case)
    elsif immigration_case?
      CalculatedHandoverDate.new(responsibility: com, reason: :immigration_case)
    elsif !earliest_release_for_handover
      CalculatedHandoverDate.new(responsibility: pom_only, reason: :release_date_unknown)
    elsif !policy_case?
      CalculatedHandoverDate.new(responsibility: com, reason: :pre_omic_rules)
    end
  end

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

  def pom_only = CalculatedHandoverDate::CUSTODY_ONLY
  def pom_with_com = CalculatedHandoverDate::CUSTODY_WITH_COM
  def com = CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
end
