# frozen_string_literal: true

class ParoleCasesController < PrisonsApplicationController
  include Sorting

  before_action :ensure_spo_user

  def index
    sorted_offenders_with_allocs = sort_collection offenders_with_allocs, default_sort: :last_name
    @offenders = Kaminari.paginate_array(sorted_offenders_with_allocs).page(page)
  end

private

  def offenders_with_allocs
    allocations = AllocationHistory.active_allocations_for_prison(@prison.code)
    offenders   = @prison.offenders.select(&:approaching_parole?)

    offenders.map { |offender|
      allocation = allocations.find_by(nomis_offender_id: offender.nomis_offender_id)
      OffenderWithAllocationPresenter.new(offender, allocation) if allocation
    }.compact
  end
end
