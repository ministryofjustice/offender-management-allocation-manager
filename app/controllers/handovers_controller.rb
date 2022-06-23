# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  include Sorting

  layout 'handovers'

  before_action :ensure_spo_user, :set_counts

  def index
    return legacy_index unless new_handovers_ui?

    redirect_to upcoming_prison_handovers_path(new_handover: params[:new_handover], prison_id: active_prison_id)
  end

  def upcoming
    @upcoming = HandoverOffender.upcoming
  end

private

  def legacy_index
    @pending_handover_count = @current_user.allocations.count(&:approaching_handover?)
    offender_list = @prison.offenders.select(&:approaching_handover?)
    allocations = @prison.allocations.where(nomis_offender_id: offender_list.map(&:offender_no))
    offenders_with_allocs = offender_list.map do |o|
      OffenderWithAllocationPresenter.new(o, allocations.detect { |a| a.nomis_offender_id == o.offender_no })
    end
    offenders = sort_collection offenders_with_allocs, default_sort: :last_name
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render :legacy_index
  end

  def new_handovers_ui?
    params[:new_handover] == NEW_HANDOVER_TOKEN
  end

  def set_counts
    @counts = HandoverOffender.counts
  end
end
