class AllocateController < ApplicationController
  before_action :authenticate_user

  def show
    @prisoner = prisoner
    @recommended_pom = @prisoner.current_responsibility

    pom_response = StaffService.get_prisoner_offender_managers(caseload)
    @recommended_poms, @not_recommended_poms = pom_response.partition { |pom|
      pom.position_description.include?(@recommended_pom)
    }
  end

  def new
    @prisoner = prisoner

    # TODO: This should not happen here, we should use an amalgamation
    # of the StaffService and PrisonOffenderManagerService
    poms_list = Nomis::Elite2::Api.prisoner_offender_manager_list(caseload)
    @pom = poms_list.data.select { |p| p.staff_id == nomis_staff_id }.first
  end

  def create
    AllocationService.create_allocation(
      nomis_staff_id: nomis_staff_id.to_i,
      nomis_offender_id: nomis_offender_id,
      created_by: current_user,
      nomis_booking_id: prisoner.latest_booking_id,
      allocated_at_tier: prisoner.tier,
      prison: caseload
    )

    redirect_to allocations_path
  end

private

  def prisoner
    OffenderService.new.get_offender(nomis_offender_id).data
  end

  def nomis_offender_id
    params.require(:nomis_offender_id)
  end

  def nomis_staff_id
    params.require(:nomis_staff_id)
  end
end
