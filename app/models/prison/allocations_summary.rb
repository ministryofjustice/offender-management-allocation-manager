class Prison::AllocationsSummary
  def initialize(prison)
    @prison = prison
    build_summary
  end

  def allocated = @summary[:allocated]
  def unallocated = @summary[:unallocated]
  def missing_info = @summary[:missing_info]
  def outside_omic_policy = @summary[:outside_omic_policy]

private

  def build_summary
    @summary = @prison.unfiltered_offenders.group_by do |offender|
      if !offender.inside_omic_policy?
        :outside_omic_policy
      elsif @prison.offender_allocatable?(offender) && @prison.offender_allocated?(offender)
        :allocated
      elsif @prison.offender_allocatable?(offender)
        :unallocated
      else
        :missing_info
      end
    end
    @summary.default = []
  end
end
