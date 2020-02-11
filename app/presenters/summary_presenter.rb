class SummaryPresenter
  attr_reader :unallocated_total, :allocated_total, :pending_total, :new_arrivals_total

  def initialize(summary)
    @unallocated_total = summary.unallocated.count
    @allocated_total = summary.allocated.count
    @pending_total = summary.pending.count
    @new_arrivals_total = summary.new_arrivals.count
  end
end
