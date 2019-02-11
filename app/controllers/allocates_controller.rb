class AllocateController < ApplicationController
  before_action :authenticate_user

  def show
    @prisoner = prisoner
    @recommended_pom = @prisoner.current_responsibility

    pom_response = PrisonOffenderManagerService.get_poms(caseload)
    @recommended_poms, @not_recommended_poms = pom_response.partition { |pom|
      pom.position_description.include?(@recommended_pom)
    }
  end

  def new
    @prisoner = prisoner

    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select { |p| p.staff_id == params.require(:nomis_staff_id) }.first
  end

  # rubocop:disable Metrics/MethodLength
  def create
    @override = Override.where(
      nomis_offender_id: nomis_offender_id).
      where(nomis_staff_id: nomis_staff_id)

    AllocationService.create_allocation(
      nomis_staff_id: allocation_params[:nomis_staff_id].to_i,
      nomis_offender_id: allocation_params[:nomis_offender_id],
      created_by: current_user,
      nomis_booking_id: prisoner.latest_booking_id,
      allocated_at_tier: prisoner.tier,
      prison: caseload,
      override_reason: override_reason,
      override_detail: override_detail
    )

    delete_override

    redirect_to allocations_path
  end
# rubocop:enable Metrics/MethodLength

private

  def prisoner
    OffenderService.new.get_offender(params.require(:nomis_offender_id)).data
  end

  def allocation_params
    params.require(:allocation).permit(:nomis_staff_id, :nomis_offender_id)
  end

  def override_reason
    @override.present? ? @override.first[:override_reason] : nil
  end

  def override_detail
    @override.present? ? @override.first[:override_detail] : nil
  end

  def delete_override
    if @override.present?
      @override.first.destroy
    end
  end
end
