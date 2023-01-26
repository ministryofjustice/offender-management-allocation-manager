module Handovers
  module HandoverCasesViewModeHelper
    # @return [pom_view: Boolean, handover_cases: Handover::CategorisedHandoverCases]
    def handover_cases_view(current_user:, prison:, current_user_is_pom:, current_user_is_spo:, pom_param: '')
      if (current_user_is_pom && current_user_is_spo && pom_param.present?) ||
        (current_user_is_pom && !current_user_is_spo)
        [true, Handover::CategorisedHandoverCasesForPom.new(current_user)]
      elsif current_user_is_spo
        [false, Handover::CategorisedHandoverCasesForHomd.new(prison)]
      else
        nil
      end
    end
  end
end
