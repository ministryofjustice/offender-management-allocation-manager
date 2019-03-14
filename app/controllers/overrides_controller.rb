class OverridesController < ApplicationController
  def new
    @prisoner = OffenderService.get_offender(params.require(:nomis_offender_id))
    @pom = PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])
    @override = Override.new
    @recommended_case_owner = ResponsibilityService.calculate_case_owner(@prisoner)

    @complex_label = complex_reason_label
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
    @recommended_case_owner = ResponsibilityService.calculate_case_owner(@prisoner)
    @pom = PrisonOffenderManagerService.get_pom(
      active_caseload, override_params[:nomis_staff_id])
    @complex_label = complex_reason_label

    render :new
  end
# rubocop:enable Metrics/MethodLength

private

  def complex_reason_label
    if @recommended_case_owner == 'Prison'
      return 'Prisoner assessed as not suitable for a prison officer POM'
    end

    'Prisoner assessed as suitable for a prison officer POM despite tiering calculation'
  end

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
