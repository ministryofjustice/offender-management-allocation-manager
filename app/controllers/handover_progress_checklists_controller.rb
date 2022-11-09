class HandoverProgressChecklistsController < PrisonsApplicationController
  def edit
    @offender = OffenderService.get_offender(params[:nomis_offender_id])
    @handover_progress_checklist = HandoverProgressChecklist.find_or_initialize_by(
      nomis_offender_id: @offender.offender_no)
  end

  def update
    raise NotImplementedError, "request params: #{params.inspect}"
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
