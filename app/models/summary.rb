# frozen_string_literal: true

class Summary
  attr_accessor :allocated, :unallocated, :pending, :new_arrivals

  # rubocop:disable Metrics/ParameterLists
  def initialize(summary_type, offenders:, allocated_total:, unallocated_total:, pending_total:, new_arrivals_total:)
    @summary_type = summary_type
    @offenders = offenders
    @allocated_total = allocated_total
    @unallocated_total = unallocated_total
    @pending_total = pending_total
    @new_arrivals_total = new_arrivals_total
  end
  # rubocop:enable Metrics/ParameterLists
end
