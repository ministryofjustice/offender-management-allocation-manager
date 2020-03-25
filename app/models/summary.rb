# frozen_string_literal: true

class Summary
  attr_accessor :allocated, :unallocated, :pending, :new_arrivals, :handovers
  def initialize(summary_type, buckets)
    @summary_type = summary_type
    @allocated = buckets[:allocated]
    @unallocated = buckets[:unallocated]
    @pending = buckets[:pending]
    @new_arrivals = buckets[:new_arrivals]
    @handovers = buckets[:handovers]
  end
end
