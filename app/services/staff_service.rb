class StaffService

  def get_prisoner_offender_managers(prison)
    poms = Nomis::Elite2::Api.get_prisoner_offender_manager_list(prison)
    staff_ids = poms.data.map(&:staff_id)

    allocations = Allocation::Api.get_allocation_data(staff_ids)

    poms.data.each do |pom|
      pom.tier_a = allocations[pom.tier_a]
      pom.tier_b = allocations[pom.tier_b]
      pom.tier_c = allocations[pom.tier_c]
      pom.tier_d = allocations[pom.tier_d]
      pom.total_cases = allocations[pom.total_cases]
    end

    poms
  end
end
