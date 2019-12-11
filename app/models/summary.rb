# frozen_string_literal: true

class Summary
  attr_accessor :allocated, :unallocated, :pending

  def initialize(summary_type)
    @summary_type = summary_type
  end
end
