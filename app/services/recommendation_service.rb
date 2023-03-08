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

  def self.recommended_pom_type_reason(offender)
    if offender.immigration_case?
      'This is an immigration case, so should be given to a <strong>prison POM</strong>'.html_safe
    elsif offender.pom_responsible?
      if %w[A B].include?(offender.tier)
        "#{offender.first_name.capitalize} is tier #{offender.tier}, so we recommend allocating to a <strong>probation POM</strong>".html_safe
      else
        "As #{offender.first_name.capitalize} is tier #{offender.tier}, we recommend allocating to a <strong>prison POM</strong>".html_safe
      end
    else
      "#{offender.first_name.capitalize} needs a POM in a supporting role, so should be allocated to a <strong>prison POM</strong>".html_safe
    end
  end
end
