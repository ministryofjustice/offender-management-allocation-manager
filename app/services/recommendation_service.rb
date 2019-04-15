# frozen_string_literal: true

class RecommendationService
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'

  def self.recommended_pom_type(offender)
    return PROBATION_POM if %w[A B].include?(offender.tier)

    PRISON_POM
  end

  def self.recommended_poms(offender, poms)
    # Returns a pair of lists where the first element contains the
    # POMs from the `poms` parameter that are recommended for the
    # `offender`
    recommended_type = recommended_pom_type(offender)
    poms.partition { |pom|
      pom.position.include?(recommended_type)
    }
  end
end
