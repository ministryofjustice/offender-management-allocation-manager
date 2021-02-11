module BadgeHelper
  def badge_colour(offender)
    if offender.indeterminate_sentence?
      'purple'
    else
      'blue'
    end
  end

  def badge_text(offender)
    if offender.indeterminate_sentence?
      'Indeterminate'
    else
      'Determinate'
    end
  end

  def badge_for_parole?(offender)
    offender.tariff_date.present? || offender.parole_eligibility_date.present? || parole_review_date?(offender)
  end

  def parole_review_date?(offender)
    offender.indeterminate_sentence? && offender.parole_review_date.present?
  end

  def early_allocation_notes?(offender, early_allocations)
    if early_allocations.any?
      !offender.within_early_allocation_window? || early_allocations.last.community_decision == false
    end
  end

  def early_allocation_active?(early_allocations)
    early_allocations.any? && early_allocations.last.awaiting_community_decision?
  end

  def early_allocation_approved?(early_allocations)
    early_allocations.any? && early_allocations.last.created_within_referral_window? && early_allocations.last.community_decision_eligible_or_automatically_eligible?
  end
end
