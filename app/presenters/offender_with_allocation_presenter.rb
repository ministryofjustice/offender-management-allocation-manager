# frozen_string_literal: true

# This class is another attempt to merge a 'prisoner' with an 'allocation'
# despite the fact that this should be really easy in theory
class OffenderWithAllocationPresenter
  include SortableAllocation

  delegate :offender_no, :full_name, :last_name, :earliest_release_date, :earliest_release, :latest_temp_movement_date, :allocated_com_name,
           :enhanced_handover?, :date_of_birth, :tier, :probation_record, :handover_start_date, :restricted_patient?,
           :location, :responsibility_handover_date, :pom_responsible?, :pom_supporting?, :coworking?, :prison, :active_allocation,
           :next_parole_date, :next_parole_date_type, to: :@offender

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
