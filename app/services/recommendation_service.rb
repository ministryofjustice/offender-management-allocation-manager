# frozen_string_literal: true

class RecommendationService
  # yes this looks backwards. However the string 'PRO' already existed in NOMIS for 'PRISON_OFFICER'
  # so 'PO' was chosen for 'Probation Officer'
  PRISON_POM = 'PRO'
  PROBATION_POM = 'PO'

  POM_TYPE_LABELS = {
    PRISON_POM => 'prison',
    PROBATION_POM => 'probation',
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

    def reason(key, **options)
      I18n.t(key, scope: 'recommendation_service.reasons', **options).html_safe
    end

  private

    def strategy
      FeatureFlags.rosh_recommendations.enabled? ? RoshStrategy : TierStrategy
    end
  end
end
