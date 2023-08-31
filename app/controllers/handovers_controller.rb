# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  include Sorting

  layout 'handovers'

  before_action :check_prerequisites_and_prepare_variables

  def upcoming
    @filtered_handover_cases = sort_and_paginate(@handover_cases.upcoming)
  end

  def in_progress
    @filtered_handover_cases = sort_and_paginate(@handover_cases.in_progress)
  end

  def overdue_tasks
    @filtered_handover_cases = sort_and_paginate(@handover_cases.overdue_tasks)
  end

  def com_allocation_overdue
    @filtered_handover_cases = sort_and_paginate(@handover_cases.com_allocation_overdue)
  end

private

  def permitted_params
    params.permit(:prison_id, :pom, :sort)
  end

  def check_prerequisites_and_prepare_variables
    if params[:sort].blank?
      redirect_to permitted_params.merge(sort: 'handover_date asc')
      return
    end

    @pom_view, @handover_cases = helpers.handover_cases_view(current_user: @current_user,
                                                             prison: @prison,
                                                             current_user_is_pom: current_user_is_pom?,
                                                             current_user_is_spo: current_user_is_spo?,
                                                             for_pom: params[:pom])

    if @handover_cases.nil?
      redirect_to '/401'
      return
    end

    @prison_id = active_prison_id
    flash[:current_handovers_url] = request.original_url
  end
end
