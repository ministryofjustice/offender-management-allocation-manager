class AllocateController < ApplicationController
  before_action :authenticate_user

  def show
    @prisoner = prisoner

    pom_response = StaffService.new.get_prisoner_offender_managers(caseload)
    @poms = pom_response.data
  end

  def new
    @prisoner = prisoner

    pom_response = StaffService.new.get_prisoner_offender_managers(caseload)
    @pom = pom_response.data.select { |p| p.staff_id == nomis_staff_id }.first
  end

  def create
    Allocation::Api.allocate(
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
    response = OffenderService.new.get_offender(nomis_offender_id)
    @prisoner = response.data
  end

  def nomis_offender_id
    params.require(:nomis_offender_id)
  end

  def nomis_staff_id
    params.require(:nomis_staff_id)
  end
end
