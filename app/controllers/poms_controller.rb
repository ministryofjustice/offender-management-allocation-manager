class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { pom.full_name },
    -> {  poms_path(params[:nomis_staff_id]) }, only: [:show]
  breadcrumb 'My caseload', :my_caseload_path, only: [:new_cases]
  breadcrumb -> { 'My caseload' },
    -> { my_caseload_path(1) }, only: [:my_caseload]
  breadcrumb -> { 'New cases' },
    -> { new_cases_path(1) }, only: [:new_cases]

  def index
    poms = PrisonOffenderManagerService.get_poms(caseload)
    @active_poms, @inactive_poms = poms.partition { |pom|
      pom.status == 'active'
    }
  end

  def show
    @pom = pom
    @allocations = PrisonOffenderManagerService.get_allocated_offenders(@pom.staff_id)
  end

  def edit; end

  def my_caseload
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(current_user)
    @allocations = PrisonOffenderManagerService.get_allocated_offenders(@pom.staff_id)
    @new_cases = PrisonOffenderManagerService.get_new_cases(@pom.staff_id)
  end

  def new_cases
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(current_user)
    @new_cases = PrisonOffenderManagerService.get_new_cases(@pom.staff_id)
  end

private

  def pom
    PrisonOffenderManagerService.get_pom(caseload, params[:nomis_staff_id])
  end
end
