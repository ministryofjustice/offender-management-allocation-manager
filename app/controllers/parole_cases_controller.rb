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
