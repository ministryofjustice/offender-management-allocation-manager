class HandoverProgressChecklistsController < PrisonsApplicationController
  def edit
    @handover_progress_checklist = HandoverProgressChecklist.find_or_initialize_by(
      nomis_offender_id: params[:nomis_offender_id])
  end

  def update
    raise NotImplementedError, "request params: #{params.inspect}"
  end
end
