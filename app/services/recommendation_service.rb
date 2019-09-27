# frozen_string_literal: true

class RecommendationService
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'

  # def self.recommended_pom_type(offender)
  #   if ResponsibilityService.calculate_pom_responsibility(offender).custody?
  #     if %w[A B].include?(offender.tier)
  #       PROBATION_POM
  #     else
  #       PRISON_POM
  #     end
  #   else
  #     PRISON_POM
  #   end
  # end

  def self.recommended_pom_type(offender)
    return PROBATION_POM if %w[A B].include?(offender.tier)

    PRISON_POM
  end
end
