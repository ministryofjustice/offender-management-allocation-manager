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
    offender.tariff_date.present? || offender.parole_eligibility_date.present? || target_hearing_date?(offender)
  end

  def target_hearing_date?(offender)
    offender.indeterminate_sentence? && offender.target_hearing_date.present?
  end
end
