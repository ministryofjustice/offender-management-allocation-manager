class Prison::AllocationsSummary
  def initialize(allocations:, offenders:)
    @allocations = allocations
    @offenders = offenders
  end

  def allocated = summary.fetch(:allocated, [])
  def unallocated = summary.fetch(:unallocated, [])
  def missing_info = summary.fetch(:missing_info, [])

  def allocation_for(offender_or_nomis_offender_id)
    nomis_offender_id = offender_or_nomis_offender_id
      .try(:nomis_offender_id) || offender_or_nomis_offender_id
    allocations_by_id[nomis_offender_id]
  end

private

  def summary
    @summary ||= @offenders.group_by do |offender|
      if offender.allocatable?
        allocation_for(offender).present? ? :allocated : :unallocated
      else
        :missing_info
      end
    end
  end

  def allocations_by_id
    @allocations_by_id ||= @allocations.index_by(&:nomis_offender_id)
  end
end
