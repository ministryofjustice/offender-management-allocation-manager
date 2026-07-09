class HandoverProgressChecklistsController < PrisonsApplicationController
  before_action :load_offender, :ensure_allocated_pom, :ensure_handover_in_progress

  def edit
    flash.keep(:current_handovers_url)
    @prison_id = active_prison_id
    @handover_progress_checklist = HandoverProgressChecklist.find_or_initialize_by(nomis_offender_id:)
  end

  def update
    checklist = HandoverProgressChecklist.find_or_initialize_by(nomis_offender_id:)
    checklist.attributes = handover_progress_checklist_params(@offender)
    checklist.save!

    flash[:handover_success_notice] = "Handover tasks for #{@offender.full_name_ordered} updated"
    redirect_to helpers.last_handovers_url
  end

private

  def load_offender
    @offender = get_offender_or_404(nomis_offender_id)
  end

  def ensure_allocated_pom
    return if @current_user.has_allocation?(nomis_offender_id)

    redirect_to '/401'
  end

  def ensure_handover_in_progress
    return redirect_to('/401') if offender_released?
    return if CalculatedHandoverDate.in_handover_window?(nomis_offender_id)

    redirect_to '/401'
  end

  def offender_released?
    @offender.earliest_release_date.present? && @offender.earliest_release_date <= Time.zone.today
  end

  def nomis_offender_id
    params.fetch(:nomis_offender_id)
  end

  def handover_progress_checklist_params(offender)
    fields = HandoverProgressChecklist.permitted_task_fields(handover_type: offender.handover_type)
    params.require(:handover_progress_checklist).permit(*fields)
  end
end
