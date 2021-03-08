# frozen_string_literal: true

# This class is a 'presenter' designed to prevent clients having to know whether
# a field lives in the allocation or sentence details when both are returned
# e.g. PomCaseload.new().allocations
#
class AllocatedOffender
  delegate :last_name, :full_name, :earliest_release_date, :approaching_handover?,
           :sentence_start_date, :tier, :cell_location, :latest_temp_movement_date, to: :@offender
  delegate :updated_at, :nomis_offender_id, :primary_pom_allocated_at, :prison,
           to: :@allocation

  attr_reader :offender

  def initialize(staff_id, allocation, offender)
    @staff_id = staff_id
    @allocation = allocation
    @offender = offender
  end

  def pom_responsibility
    if @allocation.primary_pom_nomis_id == @staff_id
      @offender.pom_responsibility.responsible? ? 'Responsible' : 'Supporting'
    else
      'Co-Working'
    end
  end

  def new_case?
    @allocation.new_case_for(@staff_id)
  end
end
