# frozen_string_literal: true

module AllocationPomEligibility
private

  def eligible_allocation_poms(poms, allocation)
    currently_allocated_staff_ids = [
      allocation&.primary_pom_nomis_id,
      allocation&.secondary_pom_nomis_id
    ].compact

    poms.select(&:active?)
        .reject { |pom| currently_allocated_staff_ids.include?(pom.staff_id) }
  end
end
