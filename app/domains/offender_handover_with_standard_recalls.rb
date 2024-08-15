class OffenderHandoverWithStandardRecalls < OffenderHandover
  def as_calculated_handover_date
    indeterminate_sentences ||
    standard_recalls_sub_12_months ||
    standard_recalls_at_20_months_or_more ||
    edge_cases ||
    general_rules
  end

private

  def standard_recalls_sub_12_months
    return unless !indeterminate_sentence? && recalled? && (
      sentences.single_sentence? ||
      sentences.concurrent_sentence_of_12_months_or_under?
    )

    if most_recent_parole_review&.has_hearing_outcome?
      CalculatedHandoverDate.new(responsibility: com, reason: :recall_release_soon)
    end
  end

  def standard_recalls_at_20_months_or_more
    return unless !indeterminate_sentence? && recalled? \
      && sentences.concurrent_sentence_of_20_months_or_over?

    if most_recent_parole_review&.cancelled? && mappa_level.in?([2, 3])
      CalculatedHandoverDate.new(responsibility: com, reason: :recall_release_later_mappa_2_3)
    elsif most_recent_parole_review&.cancelled? && mappa_level.in?([nil, 1])
      CalculatedHandoverDate.new(responsibility: pom_with_com, reason: :recall_release_later_mappa_empty_1)
    elsif most_recent_parole_review.present?
      CalculatedHandoverDate.new(responsibility: com, reason: :recall_release_later_no_outcome)
    end
  end
end
