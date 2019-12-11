class SummaryPresenter
  attr_reader :unallocated_total, :allocated_total, :pending_total

  def initialize(summary)
    @unallocated_total = summary.unallocated.count
    @allocated_total = summary.allocated.count
    @pending_total = summary.pending.count
  end
end
