# frozen_string_literal: true

class OverridesController < PrisonsApplicationController
  def new
    @prisoner = OffenderService::Get.call(params.require(:nomis_offender_id))
    @pom = POM::GetPom.call(active_prison, params[:nomis_staff_id])
    @recommended_pom_type, @not_recommended_pom_type =
      recommended_and_nonrecommended_poms_types_for(@prisoner)

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

    @prisoner = OffenderService::Get.call(override_params[:nomis_offender_id])
    @pom = POM::GetPom.call(
      active_prison, override_params[:nomis_staff_id])
    @recommended_pom_type, @not_recommended_pom_type =
      recommended_and_nonrecommended_poms_types_for(@prisoner)

    render :new
  end

private

  def recommended_and_nonrecommended_poms_types_for(offender)
    rec_type = RecommendationService.recommended_pom_type(offender)

    if rec_type == RecommendationService::PRISON_POM
      ['Prison officer',
       'Probation officer']
    else
      ['Probation officer',
       'Prison officer']
    end
  end

  def redirect_on_success
    redirect_to prison_confirm_allocation_path(
      active_prison,
      override_params[:nomis_offender_id],
      override_params[:nomis_staff_id]
    )
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
