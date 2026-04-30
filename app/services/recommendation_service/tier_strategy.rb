# frozen_string_literal: true

class RecommendationService
  class TierStrategy
    HIGH_TIERS = %w[A B].freeze

    def self.recommended_pom_type(offender)
      return PRISON_POM if offender.immigration_case? || !offender.pom_responsible?
      return PROBATION_POM if HIGH_TIERS.include?(offender.tier)

      PRISON_POM
    end

    def self.recommended_pom_type_reason(offender)
      tier = offender.tier
      name = offender.first_name.capitalize
      pom_type = POM_TYPE_LABELS.fetch(recommended_pom_type(offender))

      return RecommendationService.reason(:immigration_case) if offender.immigration_case?
      return RecommendationService.reason(:supporting_role, name:) unless offender.pom_responsible?

      RecommendationService.reason(:tier_based, name:, tier:, pom_type:)
    end
  end
end
