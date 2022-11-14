class HandoverProgressChecklistsController < PrisonsApplicationController
  def edit
    @offender = OffenderService.get_offender(params[:nomis_offender_id])
    unless @offender
      redirect_to '/404'
      return
    end
    @handover_progress_checklist = HandoverProgressChecklist.find_or_initialize_by(
      nomis_offender_id: @offender.offender_no)
  end

  def update
    nomis_offender_id = params[:nomis_offender_id]
    unless OffenderService.get_offender(nomis_offender_id)
      redirect_to '/404'
      return
    end

    checklist = HandoverProgressChecklist.find_or_initialize_by(nomis_offender_id: nomis_offender_id)
    checklist.attributes = handover_progress_checklist_params
    checklist.save!
    redirect_to prison_edit_handover_progress_checklist_path(@prison.code, nomis_offender_id)
  end

private

  def handover_progress_checklist_params
    params.require(:handover_progress_checklist).permit(
      :reviewed_oasys,
      :contacted_com,
      :attended_handover_meeting,
    )
  end
end
