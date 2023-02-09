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

  def upcoming
    @filtered_handover_cases = filtered_handover_cases(@handover_cases.upcoming)
  end

  def in_progress
    @filtered_handover_cases = filtered_handover_cases(@handover_cases.in_progress)
  end

  def overdue_tasks
    @filtered_handover_cases = filtered_handover_cases(@handover_cases.overdue_tasks)
  end

  def com_allocation_overdue
    @filtered_handover_cases = filtered_handover_cases(@handover_cases.com_allocation_overdue)
  end

private

  def permitted_params
    params.permit(:prison_id, :pom, :sort)
  end

  def check_prerequisites_and_prepare_variables
    unless session[:new_handovers_ui] == true
      redirect_to '/401'
      return
    end

    if params[:sort].blank?
      redirect_to permitted_params.merge(sort: 'handover_date asc')
      return
    end

    @pom_view, @handover_cases = helpers.handover_cases_view(current_user: @current_user,
                                                             prison: @prison,
                                                             current_user_is_pom: current_user_is_pom?,
                                                             current_user_is_spo: current_user_is_spo?,
                                                             pom_param: params[:pom])

    if @handover_cases.nil?
      redirect_to '/401'
      return
    end

    @prison_id = active_prison_id
    flash[:current_handovers_url] = request.url
  end

  def filtered_handover_cases(cases)
    sorted_cases = sort_collection cases, default_sort: :handover_date, default_direction: :asc
    Kaminari.paginate_array(sorted_cases).page(page)
  end
end
