# frozen_string_literal: true

class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { pom.full_name },
    -> {  poms_path(params[:nomis_staff_id]) }, only: [:show]

  def index
    poms = PrisonOffenderManagerService.get_poms(active_caseload)
    @active_poms, @inactive_poms = poms.partition { |pom|
      %w[active unavailable].include? pom.status
    }
  end

  def show
    @pom = pom
    @allocations = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_caseload
    )
  end

  def edit
    @pom = PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])
  end

  def update
    @pom = PrisonOffenderManagerService.get_pom_detail(params[:nomis_staff_id])
    PrisonOffenderManagerService.update_pom(
      nomis_staff_id: params[:nomis_staff_id].to_i,
      working_pattern: edit_pom_params[:working_pattern],
      status: edit_pom_params[:status]
    )
    redirect_to poms_path(id: @pom.nomis_staff_id)
  end

private

  def pom
    PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status)
  end
end
