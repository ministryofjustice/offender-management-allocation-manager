# frozen_string_literal: true

class PomsController < PrisonStaffApplicationController
  before_action :ensure_spo_user

  before_action :load_pom_staff_member, except: [:index, :show_non_pom]
  before_action :ensure_pom_is_editable, only: [:edit, :update]

  def index
    @poms = @prison.get_list_of_poms.sort_by(&:full_name_ordered)
    @removed_poms = @prison.get_removed_poms(existing_poms: @poms)
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
    @edit_pom_form = PomProfileForm.new(
      status: @pom.status,
      description: @pom.working_pattern.to_s == '1.0' ? 'FT' : 'PT',
      working_pattern: @pom.working_pattern.to_s,
    )
  end

  def update
    @edit_pom_form = PomProfileForm.new(edit_pom_params.to_h)

    if @edit_pom_form.valid?
      if @edit_pom_form.deleting?
        redirect_to confirm_delete_prison_pom_path(active_prison_id, nomis_staff_id) and return
      end

      pom_detail = @prison.pom_details.find_by!(nomis_staff_id:)
      pom_detail.working_pattern = @edit_pom_form.working_pattern_ratio
      pom_detail.status = @edit_pom_form.status
      pom_detail.save!

      if pom_detail.inactive?
        if FeatureFlags.status_bulk_reallocation.enabled? && pom_detail.has_primary_allocations?
          redirect_to reallocate_prison_pom_path(active_prison_id, nomis_staff_id:) and return
        else
          AllocationHistory.deallocate_pom(
            nomis_staff_id, active_prison_id, event_trigger: AllocationHistory::INACTIVE_POM
          )
        end
      end

      redirect_to prison_pom_path(active_prison_id, id: nomis_staff_id),
                  notice: "Profile updated for #{helpers.full_name_ordered(@pom)}"
    else
      render :edit
    end
  end

  def reallocate
    unless @pom.inactive? || @pom.in_limbo?
      # TODO: maybe design a nicer informational page?
      redirect_to prison_pom_path, notice: 'Only inactive POMs are eligible for bulk case reallocation.'
    end

    pom_allocations_summary
  end

  def confirm_removal; end

  def confirm_delete
    @confirm_delete_form = ConfirmDeletePomForm.new
  end

  def destroy
    # Legacy flow (limbo poms removal without confirmation form)
    # TODO: to be removed once we release the new bulk-reallocation feature
    unless params.key?(:confirm_delete_pom)
      NomisUserRolesService.remove_pom(@prison, nomis_staff_id)
      redirect_to prison_poms_path(anchor: 'attention_needed!top'),
                  notice: "#{@pom.full_name_or_staff_id} removed. If necessary, their cases have been moved to @unallocated_link@."
      return
    end

    # New flow (confirm_delete form submission)
    @confirm_delete_form = ConfirmDeletePomForm.new(confirm_delete_params)

    if @confirm_delete_form.valid?
      if @confirm_delete_form.confirmed?
        pom_detail = @prison.pom_details.find_by!(nomis_staff_id:)

        if pom_detail.has_primary_allocations?
          pom_detail.deleted!
          redirect_to reallocate_prison_pom_path(active_prison_id, nomis_staff_id:)
        else
          NomisUserRolesService.remove_pom(@prison, nomis_staff_id)
          redirect_to prison_poms_path(active_prison_id),
                      notice: "#{@pom.full_name_or_staff_id} successfully removed from this service"
        end
      else
        redirect_to edit_prison_pom_path(active_prison_id, nomis_staff_id)
      end
    else
      render :confirm_delete
    end
  end

private

  def ensure_pom_is_editable
    unless @pom.editable?
      redirect_to prison_pom_path(active_prison_id, id: nomis_staff_id),
                  notice: 'This POM has been removed and their profile cannot be edited.'
    end
  end

  def load_pom_staff_member
    @pom = StaffMember.new @prison, nomis_staff_id
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status, :description)
  end

  def confirm_delete_params
    params.fetch(:confirm_delete_pom, {}).permit(:confirmation)
  end

  def nomis_staff_id
    params[:nomis_staff_id].to_i
  end
end
