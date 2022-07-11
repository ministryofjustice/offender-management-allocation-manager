# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  include Sorting

  layout 'handovers'

  before_action :check_prerequisites_and_prepare_variables, except: :index

  def index
    return legacy_index unless new_handovers_ui?

    redirect_to upcoming_prison_handovers_path(new_handover: params[:new_handover], prison_id: active_prison_id)
  end

  def upcoming
    if params[:static_design]
      render 'handovers/upcoming/static_design'
      return
    end

    @counts = @handover_case_listing.counts
    @upcoming_handovers = @handover_case_listing.upcoming(@pom)
  end

private

  def legacy_index
    ensure_spo_user
    @pending_handover_count = @current_user.allocations.count(&:approaching_handover?)
    offender_list = @prison.offenders.select(&:approaching_handover?)
    allocations = @prison.allocations.where(nomis_offender_id: offender_list.map(&:offender_no))
    offenders_with_allocs = offender_list.map do |o|
      MpcOffenderWithAllocation.new(o, allocations.detect { |a| a.nomis_offender_id == o.offender_no })
    end
    offenders = sort_collection offenders_with_allocs, default_sort: :last_name
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render :legacy_index, layout: 'application'
  end

  def new_handovers_ui?
    params[:new_handover] == NEW_HANDOVER_TOKEN
  end

  def check_prerequisites_and_prepare_variables
    ensure_pom
    redirect_to '/401' unless new_handovers_ui?
    @pom = StaffMember.new(@prison, @staff_id)
    @handover_case_listing = HandoverCaseListingService.new
  end
end
