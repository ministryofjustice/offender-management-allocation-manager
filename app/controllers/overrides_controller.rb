# frozen_string_literal: true

class OverridesController < PrisonsApplicationController
  def new
    @prisoner = OffenderService.get_offender(params.require(:nomis_offender_id))
    @pom = PrisonOffenderManagerService.get_pom(active_prison, params[:nomis_staff_id])

    @override = Override.new
  end

  def create
    @override = AllocationService.create_override(
      nomis_staff_id: override_params[:nomis_staff_id],
      nomis_offender_id: override_params[:nomis_offender_id],
      override_reasons: override_params[:override_reasons],
      suitability_detail: override_params[:suitability_detail],
      more_detail: override_params[:more_detail]
    )

    return redirect_on_success if @override.valid?

    @prisoner = OffenderService.get_offender(override_params[:nomis_offender_id])
    @pom = PrisonOffenderManagerService.get_pom(
      active_prison, override_params[:nomis_staff_id])

    render :new
  end

private

  def redirect_on_success
    previously_allocated = AllocationService.previously_allocated_poms(
      override_params[:nomis_offender_id]
    )

    if previously_allocated.empty?
      redirect_to prison_confirm_allocation_path(
        active_prison,
        override_params[:nomis_offender_id],
        override_params[:nomis_staff_id],
        sort: params[:sort],
        page: params[:page]
      )
    else
      redirect_to prison_confirm_reallocation_path(
        active_prison,
        override_params[:nomis_offender_id],
        override_params[:nomis_staff_id],
        sort: params[:sort],
        page: params[:page]
      )
    end
  end

  def override_params
    params.require(:override).permit(
      :nomis_offender_id,
      :nomis_staff_id,
      :more_detail,
      :suitability_detail,
      override_reasons: []
    )
  end
end
