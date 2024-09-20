# frozen_string_literal: true

class ParoleCasesController < PrisonsApplicationController
  include Sorting

  before_action :ensure_spo_user

  def index
    sorted_offenders_with_allocs = sort_collection offenders_with_allocs, default_sort: :last_name
    @offenders = Kaminari.paginate_array(sorted_offenders_with_allocs).page(page)
  end

private

  # Find the allocated offenders in this prison which are approaching parole

  def offenders_with_allocs
    allocations = AllocationHistory.active_allocations_for_prison(@prison.code).index_by(&:nomis_offender_id)
    offenders   = @prison.offenders.select(&:approaching_parole?)

    offenders.map { |offender|
      if (allocation = allocations[offender.nomis_offender_id])
        OffenderWithAllocationPresenter.new(offender, allocation)
      end
    }.compact
  end
end
