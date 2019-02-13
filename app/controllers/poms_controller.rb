class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { pom.full_name }, -> {  poms_show_path(params[:id]) }, only: [:show]

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

private

  def pom
    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select { |p| p.staff_id.to_i == params['id'].to_i }.first
  end
end
