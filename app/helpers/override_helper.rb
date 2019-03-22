module OverrideHelper
  def complex_reason_label(offender)
    if offender.case_owner == 'Prison'
      return 'Prisoner assessed as not suitable for a prison officer POM'
    end

    'Prisoner assessed as suitable for a prison officer POM despite tiering calculation'
  end
end
