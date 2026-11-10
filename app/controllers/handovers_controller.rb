# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  layout 'handovers'

  before_action :ensure_spo_or_pom_user
  before_action :set_default_sort
  before_action :set_prison_id
  before_action :set_current_handovers_url
  before_action :set_handover_cases
  before_action :set_pom_view

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

  def set_handover_cases
    @handover_cases = helpers.handover_cases_view(
      current_user: @current_user,
      prison: @prison,
      current_user_is_pom: current_user_is_pom?,
      current_user_is_spo: current_user_is_spo?,
      for_pom: params[:pom]
    )
  end

  def set_prison_id
    @prison_id = active_prison_id
  end

  def set_current_handovers_url
    flash[:current_handovers_url] = request.original_url
  end

  def set_pom_view
    @pom_view = !(current_user_is_spo? && params[:pom].blank?)
  end

  def set_default_sort
    params[:sort] = 'handover_date asc' if params[:sort].blank?
  end

  def ensure_spo_or_pom_user
    unless current_user_is_pom? || current_user_is_spo?
      redirect_to '/401'
    end
  end
end
