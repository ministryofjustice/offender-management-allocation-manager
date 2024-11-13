# frozen_string_literal: true

# This class is another attempt to merge a 'prisoner' with an 'allocation'
# despite the fact that this should be really easy in theory
class OffenderWithAllocationPresenter
  include SortableAllocation

  delegate :offender_no, :full_name,
           # used in the parole page
           :next_parole_date, :next_parole_date_type,
           # used in the allocated page
           :last_name, :location, :restricted_patient?, :earliest_release, :earliest_release_date, :tier, :latest_temp_movement_date,
           # needed in the caseload global page
           :pom_responsible?, :pom_supporting?,
           # needed for search
           :active_allocation, :probation_record, to: :@offender

  def initialize(offender, allocation)
    @offender = offender
    @allocation = allocation
  end

  def allocated_pom_nomis_id
    @allocation.primary_pom_nomis_id if @allocation
  end

  def allocation_date
    if @allocation
      (@allocation.primary_pom_allocated_at || @allocation.updated_at)&.to_date
    end
  end

  def primary_pom_allocated_at
    @allocation.primary_pom_allocated_at
  end
end
