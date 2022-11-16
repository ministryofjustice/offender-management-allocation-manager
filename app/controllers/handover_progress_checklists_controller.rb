class HandoverProgressChecklistsController < PrisonsApplicationController
  def edit
    with_valid_offender do |offender, nomis_offender_id|
      flash.keep[:current_handovers_url]
      @offender = offender
      @handover_progress_checklist =
        HandoverProgressChecklist.find_or_initialize_by(nomis_offender_id: nomis_offender_id)
    end
  end

  def update
    with_valid_offender do |offender, nomis_offender_id|
      unless @current_user.has_allocation?(nomis_offender_id)
        redirect_to '/401'
        return
      end

      checklist = HandoverProgressChecklist.find_or_initialize_by(nomis_offender_id: nomis_offender_id)
      checklist.attributes = handover_progress_checklist_params
      checklist.save!
      flash[:handover_success_notice] = "Handover tasks for #{offender.full_name_ordered} updated"
      redirect_to helpers.last_handovers_url
    end
  end

private

  def with_valid_offender
    nomis_offender_id = params[:nomis_offender_id]
    offender = OffenderService.get_offender(nomis_offender_id)
    unless offender
      redirect_to '/404'
      return
    end

    yield offender, nomis_offender_id
  end

  def handover_progress_checklist_params
    params.require(:handover_progress_checklist).permit(
      :reviewed_oasys,
      :contacted_com,
      :attended_handover_meeting,
    )
  end
end
