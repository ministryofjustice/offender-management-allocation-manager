class Prison::AllocationsSummary
  def initialize(prison)
    @prison = prison
    build_summary
  end

  def allocated = @summary[:allocated]
  def unallocated = @summary[:unallocated]
  def new_arrivals = @summary[:new_arrivals]
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
      elsif offender.new_arrival?
        :new_arrivals
      else
        :missing_info
      end
    end
    @summary.default = []
  end
end
