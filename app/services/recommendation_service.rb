# frozen_string_literal: true

class RecommendationService
  # yes this looks backwards. However the string 'PRO' already existed in NOMIS for 'PRISON_OFFICER'
  # so 'PO' was chosen for 'Probation Officer'
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'

  def self.recommended_pom_type(offender)
    if offender.immigration_case?
      PRISON_POM
    elsif offender.pom_responsible?
      if %w[A B].include?(offender.tier)
        PROBATION_POM
      else
        PRISON_POM
      end
    else
      PRISON_POM
    end
  end
end
