# frozen_string_literal: true

# Used to display all parole cases within a prison to the HOMD
class ParoleCasesController < PrisonsApplicationController
  include Sorting

  before_action :ensure_spo_user

  def index
    offender_list = @prison.offenders.select(&:approaching_parole?)
    allocations = @prison.allocations.where(nomis_offender_id: offender_list.map(&:offender_no))
    offenders_with_allocs = offender_list.map do |o|
      OffenderWithAllocationPresenter.new(o, allocations.detect { |a| a.nomis_offender_id == o.offender_no })
    end
    offenders = sort_collection offenders_with_allocs, default_sort: :last_name

    @offenders = Kaminari.paginate_array(offenders).page(page)
  end
end
