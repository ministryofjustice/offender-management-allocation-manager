# frozen_string_literal: true

module Reallocation
  class BulkReallocationResult
    ReallocatedCase = Struct.new(:allocation, :selected_case, :further_info, keyword_init: true) do
      def confirmation_attributes
        {
          full_name: selected_case.full_name,
          nomis_offender_id: selected_case.nomis_offender_id,
        }
      end
    end

    attr_reader :source_pom_id, :target_pom_id, :message, :reallocated_cases, :remaining_cases_count

    def initialize(source_pom_id:, target_pom_id:, message:, reallocated_cases:, remaining_cases_count:)
      @source_pom_id = source_pom_id
      @target_pom_id = target_pom_id
      @message = message
      @reallocated_cases = reallocated_cases
      @remaining_cases_count = remaining_cases_count
    end

    def selected_cases
      reallocated_cases.map(&:confirmation_attributes)
    end

    def to_confirmation
      {
        source_pom_id: source_pom_id,
        target_pom_id: target_pom_id,
        selected_cases: selected_cases,
        message: message,
        remaining_cases_count: remaining_cases_count,
      }
    end
  end
end
