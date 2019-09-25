# frozen_string_literal: true

class Summary
  attr_accessor :offenders
  attr_accessor :allocated_total, :unallocated_total, :pending_total

  def initialize(summary_type)
    @summary_type = summary_type
  end
end
