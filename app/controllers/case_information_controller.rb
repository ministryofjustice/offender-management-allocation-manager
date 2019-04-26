# frozen_string_literal: true

class CaseInformationController < ApplicationController
  before_action :authenticate_user

  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url,
      prison: active_caseload
    )

    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def edit
    @case_info = CaseInformation.find_by(
      nomis_offender_id: nomis_offender_id_from_url,
      prison: active_caseload
    )

    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      omicable: case_information_params[:omicable],
      case_allocation: case_information_params[:case_allocation],
      prison: active_caseload
    )

    return redirect_to summary_pending_path if @case_info.valid?

    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :new
  end

  def update
    case_info = CaseInformation.find_by(
      nomis_offender_id: case_information_params[:nomis_offender_id]
    )
    case_info.prison = active_caseload
    case_info.tier = case_information_params[:tier]
    case_info.case_allocation = case_information_params[:case_allocation]
    case_info.omicable = case_information_params[:omicable]
    case_info.save

    redirect_to new_allocation_path(case_info.nomis_offender_id)
  end

private

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation, :omicable)
  end
end
