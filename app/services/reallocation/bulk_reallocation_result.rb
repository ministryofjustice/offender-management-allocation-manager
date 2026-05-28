# frozen_string_literal: true

module Reallocation
  class BulkReallocationResult
    ReallocatedCase = Struct.new(:allocation, :selected_case, :further_info, :email_context, keyword_init: true) do
      def confirmation_attributes
        {
          full_name: selected_case.full_name,
          nomis_offender_id: selected_case.nomis_offender_id,
        }
      end

      def email_attributes
        offender_name = email_context.fetch(:offender_name)
        nomis_offender_id = email_context.fetch(:prisoner_number)
        pom_responsibility = email_context.fetch(:pom_role).to_s.downcase

        "#{offender_name} (#{nomis_offender_id}) – #{pom_responsibility}"
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

    def allocations_for_email
      reallocated_cases.map(&:email_attributes)
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
