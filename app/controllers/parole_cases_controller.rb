# frozen_string_literal: true

class ParoleCasesController < PrisonsApplicationController
  include Sorting

  before_action :ensure_spo_user

  def index
    offenders = params[:old].present? ? offenders_with_allocs_old : offenders_with_allocs_new

    sorted_offenders_with_allocs = sort_collection offenders, default_sort: :last_name
    @offenders = Kaminari.paginate_array(sorted_offenders_with_allocs).page(page)
  end

private

  # Find the allocated offenders in this prison which are approaching parole

  def offenders_with_allocs_new
    allocations = AllocationHistory.active_allocations_for_prison(@prison.code)
    allocations = AllocationHistory.active_allocations_for_prison(@prison.code).index_by(&:nomis_offender_id) if params[:lookup] == "index"
    offenders   = @prison.offenders.select(&:approaching_parole?)

    offenders.map { |offender|
      allocation = allocations.find_by(nomis_offender_id: offender.nomis_offender_id)            if params[:lookup] == "query"
      allocation = allocations[offender.nomis_offender_id]                                       if params[:lookup] == "index"
      allocation = allocations.find {|all| all.nomis_offender_id == offender.nomis_offender_id } if params[:lookup] == "find" || params[:lookup].nil?
      OffenderWithAllocationPresenter.new(offender, allocation) if allocation
    }.compact
  end

  def offenders_with_allocs_old
    parole_offenders.map { |offender|
      parole_allocation = parole_allocations.detect { |alloc| alloc.nomis_offender_id == offender.offender_no }
      next if parole_allocation.nil? # Only show allocated offenders

      OffenderWithAllocationPresenter.new(offender, parole_allocation)
    }.compact
  end

  def parole_offenders
    @prison.offenders.select(&:approaching_parole?)
  end

  def parole_allocations
    @prison.allocations.where(nomis_offender_id: parole_offenders.map(&:offender_no))
  end
end
