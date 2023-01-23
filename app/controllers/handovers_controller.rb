# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  include Sorting

  layout 'handovers'

  before_action :check_prerequisites_and_prepare_variables, except: :index
  before_action :ensure_spo_user, only: :index

  def index
    @pending_handover_count = @current_user.allocations.count(&:approaching_handover?)
    offender_list = @prison.offenders.select(&:approaching_handover?)
    allocations = @prison.allocations.where(nomis_offender_id: offender_list.map(&:offender_no))
    offenders_with_allocs = offender_list.map do |o|
      OffenderWithAllocationPresenter.new(o, allocations.detect { |a| a.nomis_offender_id == o.offender_no })
    end
    offenders = sort_collection offenders_with_allocs, default_sort: :last_name
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render :legacy_index, layout: 'application'
  end

  def upcoming; end

  def in_progress; end

  def overdue_tasks; end

  def com_allocation_overdue; end

private

  def new_handovers_ui?
    session[:new_handovers_ui] == true
  end

  def check_prerequisites_and_prepare_variables
    unless new_handovers_ui?
      redirect_to '/401'
      return
    end

    ensure_pom
    @prison_id = active_prison_id
    @handover_cases = Handover::CategorisedHandoverCases.new(staff_member: @current_user)
    flash[:current_handovers_url] = request.url
  end
end
