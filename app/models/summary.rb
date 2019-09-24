# frozen_string_literal: true

class Summary
  attr_accessor :offenders
  attr_accessor :allocated_total, :unallocated_total, :pending_total

  def initialize(summary_type)
    @summary_type = summary_type
  end

private

  def total_for_summary_type
    return allocated_total if @summary_type == :allocated
    return unallocated_total if @summary_type == :unallocated

    pending_total if @summary_type == :pending
  end
end
