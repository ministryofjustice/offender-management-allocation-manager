class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { pom.full_name },
    -> {  poms_path(params[:nomis_staff_id]) }, only: [:show]
  breadcrumb 'Your caseload', :my_caseload_path, only: [:new_cases]
  breadcrumb -> { 'Your caseload' },
    -> { my_caseload_path }, only: [:my_caseload]
  breadcrumb -> { 'New cases' },
    -> { new_cases_path }, only: [:new_cases]

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

  def my_caseload
    @pom = PrisonOffenderManagerService.
        get_signed_in_pom_details(current_user, active_caseload)
    if @pom.present?
      @allocations = PrisonOffenderManagerService.get_allocated_offenders(
        @pom.staff_id, active_caseload
      )
      @new_cases = PrisonOffenderManagerService.get_new_cases(
        @pom.staff_id, active_caseload
      )
    end
  end

  def new_cases
    @pom = PrisonOffenderManagerService.
        get_signed_in_pom_details(current_user, active_caseload)
    if @pom.present?
      @new_cases = PrisonOffenderManagerService.get_new_cases(
        @pom.staff_id, active_caseload
      )
    end
  end

private

  def pom
    PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status)
  end
end
