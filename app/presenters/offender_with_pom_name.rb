class OffenderWithPomName
  delegate :offender_no, :full_name, :earliest_release_date,  to: :@offender

  def initialize(offender, allocation)
    @offender = offender
    @allocation = allocation
  end

  def allocated_pom_name
    @allocation.primary_pom_name
  end

  def allocation_date
    (@allocation.primary_pom_allocated_at || @allocation.updated_at)&.to_date
  end
end
