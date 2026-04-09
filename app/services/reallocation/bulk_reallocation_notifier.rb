# frozen_string_literal: true

# TODO: this is a bit finger in the air as the handling of the new emails
# is still not ready or even started
module Reallocation
  class BulkReallocationNotifier
    def call(result)
      result.reallocated_cases.each do |reallocated_case|
        EmailService.send_email(
          allocation: reallocated_case.allocation,
          message: result.message,
          pom_nomis_id: reallocated_case.allocation.primary_pom_nomis_id,
          further_info: reallocated_case.further_info,
        )
      end
    end
  end
end
