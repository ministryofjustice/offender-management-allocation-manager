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
    offenders = @prison.allocated.select(&:approaching_parole?)
    offenders.map do |offender|
      OffenderWithAllocationPresenter.new(offender, @prison.allocation_for(offender))
    end
  end
end
