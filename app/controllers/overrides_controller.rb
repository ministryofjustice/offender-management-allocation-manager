class OverridesController < ApplicationController
  def new
    @prisoner = OffenderService.new.get_offender(params.require(:nomis_offender_id))
    @recommended_pom = @prisoner.current_responsibility
    @pom = PrisonOffenderManagerService.get_pom(caseload, params[:nomis_staff_id])
  end

  def create
    AllocationService.create_override(
      nomis_staff_id: override_params[:nomis_staff_id],
      nomis_offender_id: override_params[:nomis_offender_id],
      override_reasons: override_params[:override_reasons],
      more_detail: override_params[:more_detail]
      )

    redirect_to new_allocations_path(
      override_params[:nomis_offender_id],
      override_params[:nomis_staff_id]
    )
  end

private

  def override_params
    params.require(:override).permit(
      :nomis_offender_id, :nomis_staff_id, :more_detail, override_reasons: []
    )
  end
end
