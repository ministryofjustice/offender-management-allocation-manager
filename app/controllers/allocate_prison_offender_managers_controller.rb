class AllocatePrisonOffenderManagersController < ApplicationController
  before_action :authenticate_user

  def show; end

  def new
    response = OffenderService.new.get_offender(noms_id)
    @prisoner = response.data

    @recommended_pom = @prisoner.current_responsibility

    pom_response = StaffService.new.get_prisoner_offender_managers(caseload)
    @recommended_poms, @not_recommended_poms = pom_response.data.partition { |pom|
      pom.position_description.include?(@recommended_pom)
    }
  end

private

  def noms_id
    params.require(:noms_id)
  end
end
