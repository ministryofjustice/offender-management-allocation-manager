module Handovers
  module HandoverCasesViewModeHelper
    # @return [pom_view: Boolean, handover_cases: Handover::CategorisedHandoverCases]
    def handover_cases_view(current_user:, prison:, current_user_is_pom:, current_user_is_spo:, for_pom: '')
      if current_user_is_spo
        if for_pom.blank?
          [false, Handover::CategorisedHandoverCasesForHomd.new(prison)]
        elsif for_pom == 'user'
          [true, Handover::CategorisedHandoverCasesForPom.new(current_user)]
        else # for_pom == <pom_user_to_view>
          [true, Handover::CategorisedHandoverCasesForPom.new(for_pom)]
        end
      elsif current_user_is_pom
        [true, Handover::CategorisedHandoverCasesForPom.new(current_user)]
      else
        nil
      end
    end
  end
end
