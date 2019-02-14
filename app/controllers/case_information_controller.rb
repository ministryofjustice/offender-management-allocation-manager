class CaseInformationController < ApplicationController
  before_action :authenticate_user

  def new
    @prisoner = OffenderService.new.get_offender(nomis_offender_id_from_url).data
  end

  def create
    CaseInformation.create!(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      case_allocation: case_information_params[:case_allocation]
    )

    redirect_to allocations_path
  end

  private

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation)
  end
end
