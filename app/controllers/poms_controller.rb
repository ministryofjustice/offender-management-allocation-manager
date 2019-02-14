class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { pom.full_name }, -> {  poms_show_path(params[:id]) }, only: [:show]
  breadcrumb 'My caseload', :my_caseload_path, only: [ :new_cases]
  breadcrumb -> { 'My caseload' }, -> { my_caseload_path(1) }, only: [:my_caseload]
  breadcrumb -> { 'New cases' }, -> { new_cases_path(1) }, only: [:new_cases]

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
    user = Nomis::Elite2::Api.fetch_nomis_user_details(current_user).data
    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select { |p| p.staff_id.to_i == user.staff_id.to_i }.first
    @allocations = PrisonOffenderManagerService.get_allocated_offenders(@pom.staff_id)
    @new_cases = PrisonOffenderManagerService.get_new_cases(@pom.staff_id)
  end

  def new_cases; end
private

  def pom
    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select { |p| p.staff_id.to_i == params['id'].to_i }.first
  end
end
