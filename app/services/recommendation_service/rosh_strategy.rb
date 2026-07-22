# frozen_string_literal: true

class RecommendationService
  class RoshStrategy
    HIGH_ROSH_LEVELS = %w[VERY_HIGH HIGH].freeze

    def self.recommended_pom_type(offender)
      return PRISON_POM if offender.immigration_case? || !offender.pom_responsible?
      return PROBATION_POM if offender.tier == 'A' || HIGH_ROSH_LEVELS.include?(offender.rosh_level)
      return NO_RECOMMENDATION if offender.rosh_level.blank?

      PRISON_POM
    end

    def self.recommended_pom_type_reason(offender)
      name = offender.first_name.capitalize
      pom_type = POM_TYPE_LABELS.fetch(recommended_pom_type(offender))

      return RecommendationService.reason(:immigration_case) if offender.immigration_case?
      return RecommendationService.reason(:supporting_role, name:) unless offender.pom_responsible?
      return RecommendationService.reason(:tier_based, name:, tier: 'A', pom_type:) if offender.tier == 'A'
      return RecommendationService.reason(:missing_rosh) if offender.rosh_level.blank?

      rosh_level = offender.rosh_level.humanize.downcase
      RecommendationService.reason(:rosh_based, name:, rosh_level:, pom_type:)
    end
  end
end
