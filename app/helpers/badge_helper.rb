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
end
