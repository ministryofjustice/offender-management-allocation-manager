# frozen_string_literal: true

class ParoleCasesController < PrisonsApplicationController
  before_action :ensure_spo_user

  def index
    @offenders = sort_and_paginate(offenders_with_allocs, default_sort: :last_name)
  end

private

  def offenders_with_allocs
    allocations = AllocationHistory.active_allocations_for_prison(@prison.code)
    offenders   = @prison.offenders.select(&:approaching_parole?)

    offenders.filter_map do |offender|
      allocation = allocations.find_by(nomis_offender_id: offender.nomis_offender_id)
      OffenderWithAllocationPresenter.new(offender, allocation) if allocation
    end
  end
end
