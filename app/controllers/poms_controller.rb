# frozen_string_literal: true

class PomsController < PrisonStaffApplicationController
  before_action :ensure_spo_user

  before_action :load_pom_staff_member, only: [:show, :edit, :update, :destroy]
  before_action :store_referrer_in_session, only: [:edit]
  before_action :set_referrer

  def index
    @poms = @prison.get_list_of_poms.sort_by(&:full_name_ordered)
  end

  def show
    @tab = params[:tab] || 'overview'
    @prison_id = @prison.code
    pom_allocations_summary

    if @tab == 'handover'
      @upcoming_handovers = sort_and_paginate(@handover_cases.upcoming)
      @in_progress_handovers = sort_and_paginate(@handover_cases.in_progress)
      @overdue_tasks = sort_and_paginate(@handover_cases.overdue_tasks)
      @overdue_com_allocations = sort_and_paginate(@handover_cases.com_allocation_overdue)
    else
      @upcoming_handovers = @handover_cases.upcoming
      @in_progress_handovers = @handover_cases.in_progress
      @overdue_tasks = @handover_cases.overdue_tasks
      @overdue_com_allocations = @handover_cases.com_allocation_overdue
    end

    @pom_view = true
  end

  # This is for the situation where the user is no longer a POM
  # the user will probably mark this POM inactive
  def show_non_pom
    @nomis_staff_id = nomis_staff_id
  end

  def edit
    @errors = {}
  end

  def update
    pom_detail = @prison.pom_details.find_by!(nomis_staff_id: nomis_staff_id)
    pom_detail.working_pattern = working_pattern
    pom_detail.status = edit_pom_params[:status] || pom.status

    if pom_detail.save
      if pom_detail.status == 'inactive'
        AllocationHistory.deallocate_primary_pom(
          nomis_staff_id, active_prison_id, event_trigger: AllocationHistory::INACTIVE_POM
        )
        AllocationHistory.deallocate_secondary_pom(
          nomis_staff_id, active_prison_id, event_trigger: AllocationHistory::INACTIVE_POM
        )
      end
      redirect_to prison_pom_path(active_prison_id, id: nomis_staff_id),
                  notice: "Profile updated for #{helpers.full_name_ordered(@pom)}"
    else
      @errors = pom_detail.errors
      render :edit
    end
  end

  def destroy
    NomisUserRolesService.remove_pom(@prison, nomis_staff_id)
    redirect_to prison_poms_path(anchor: "#{params[:from]}!top"),
                notice: "#{@pom.full_name_or_staff_id} removed. Their cases have been moved to @unallocated_link@."
  end

private

  def load_pom_staff_member
    @pom = StaffMember.new @prison, nomis_staff_id
  end

  def working_pattern
    return '1.0' if edit_pom_params[:description] == 'FT'

    edit_pom_params[:working_pattern]
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status, :description)
  end

  def nomis_staff_id
    params[:nomis_staff_id].to_i
  end
end
