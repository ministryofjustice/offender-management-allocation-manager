module Handovers
  module HandoverCasesViewModeHelper
    def handover_cases_view(current_user:, prison:, current_user_is_pom:, current_user_is_spo:, for_pom: '')
      if current_user_is_spo
        handover_cases_view_for_spo(current_user:, prison:, for_pom:)
      elsif current_user_is_pom
        handover_cases_view_for_pom(current_user)
      end
    end

    def handover_cases_view_for_spo(current_user:, prison:, for_pom: '')
      if for_pom.blank?
        Handover::CategorisedHandoverCases.new(prison.primary_allocated_offenders)
      elsif for_pom == 'user'
        handover_cases_view_for_pom(current_user)
      end
    end

    def handover_cases_view_for_pom(current_user)
      Handover::CategorisedHandoverCases.new(current_user.unreleased_allocations)
    end
  end
end
