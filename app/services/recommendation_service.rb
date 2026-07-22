# frozen_string_literal: true

class RecommendationService
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'
  NO_RECOMMENDATION = 'NOREC'

  POM_TYPE_LABELS = {
    PRISON_POM => 'prison',
    PROBATION_POM => 'probation',
    NO_RECOMMENDATION => nil,
  }.freeze

  class << self
    # rubocop:disable Rails/Delegate
    def recommended_pom_type(offender)
      strategy.recommended_pom_type(offender)
    end

    def recommended_pom_type_reason(offender)
      strategy.recommended_pom_type_reason(offender)
    end
    # rubocop:enable Rails/Delegate

    def recommendation_available?(offender)
      recommended_pom_type(offender) != NO_RECOMMENDATION
    end

    def reason(key, **options)
      I18n.t(key, scope: 'recommendation_service.reasons', **options).html_safe
    end

  private

    def strategy
      FeatureFlags.rosh_recommendations.enabled? ? RoshStrategy : TierStrategy
    end
  end
end
