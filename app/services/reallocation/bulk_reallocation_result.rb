# frozen_string_literal: true

module Reallocation
  class BulkReallocationResult
    FailedCase = Struct.new(:selected_case, :error, keyword_init: true) do
      def confirmation_attributes
        {
          full_name: selected_case.full_name,
          nomis_offender_id: selected_case.nomis_offender_id,
          error_message: error.message,
        }
      end
    end

    ReallocatedCase = Struct.new(:allocation, :selected_case, :email_context, keyword_init: true) do
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

    attr_reader :source_pom_id, :target_pom_id, :message, :reallocated_cases, :failed_cases, :remaining_cases_count

    def initialize(source_pom_id:, target_pom_id:, message:, reallocated_cases:, failed_cases:, remaining_cases_count:)
      @source_pom_id = source_pom_id
      @target_pom_id = target_pom_id
      @message = message
      @reallocated_cases = reallocated_cases
      @failed_cases = failed_cases
      @remaining_cases_count = remaining_cases_count
    end

    def allocations_for_email
      reallocated_cases.map(&:email_attributes)
    end

    def to_confirmation
      {
        source_pom_id:,
        target_pom_id:,
        message:,
        selected_cases: reallocated_cases.map(&:confirmation_attributes),
        failed_cases: failed_cases.map(&:confirmation_attributes),
        remaining_cases_count:,
      }
    end
  end
end
