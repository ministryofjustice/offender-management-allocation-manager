class CalculatedResponsibility::Rules < SimpleDelegator
  def initialize(outcome_listener:, handover:, offender:)
    super(offender)
    @responsibility = outcome_listener
    @handover = handover
  end

  def outcome
    isps || edge_cases || general_cases
  end

private

  attr_reader :responsibility, :handover

  def isps
    return unless USE_PPUD_PAROLE_DATA && indeterminate_sentence?

    if parole_outcome_not_release? && thd_12_or_more_months_from_now?
      if mappa_level.in?([2, 3])
        responsibility.com :mappa_2_or_3
      else
        responsibility.pom_with_com :thd_over_12_months
      end
    elsif sentenced_to_an_additional_isp?
      responsibility.pom :additional_isp
    end
  end

  def edge_cases
    if immigration_case?
      responsibility.com :immigration_case
    elsif !earliest_release && !recalled?
      responsibility.pom :release_date_unknown
    elsif !policy_case?
      responsibility.com :pre_omic_rules
    end
  end

  def general_cases
    responsibility.is(handover.responsibility, handover.reason, with_handover: handover)
  end
end
