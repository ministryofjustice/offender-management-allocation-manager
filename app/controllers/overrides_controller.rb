class OverridesController < ApplicationController
  def new
    @prisoner = OffenderService.get_offender(params.require(:nomis_offender_id))
    @pom = PrisonOffenderManagerService.get_pom(caseload, params[:nomis_staff_id])
    @override = Override.new
  end

  # rubocop:disable Metrics/MethodLength
  def create
    @override = AllocationService.create_override(
      nomis_staff_id: override_params[:nomis_staff_id],
      nomis_offender_id: override_params[:nomis_offender_id],
      override_reasons: override_params[:override_reasons],
      more_detail: override_params[:more_detail]
    )

    return redirect_on_success if @override.valid?

    @prisoner = OffenderService.get_offender(override_params[:nomis_offender_id])
    @pom = PrisonOffenderManagerService.get_pom(
      caseload, override_params[:nomis_staff_id])

    render :new
  end
# rubocop:enable Metrics/MethodLength

private

  def redirect_on_success
    redirect_to confirm_allocations_path(
      override_params[:nomis_offender_id],
      override_params[:nomis_staff_id]
    )
  end

  def override_params
    params.require(:override).permit(
      :nomis_offender_id, :nomis_staff_id, :more_detail, override_reasons: []
    )
  end
end
