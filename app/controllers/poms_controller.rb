class PomsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Prison Offender Managers', :poms_path, only: [:index, :show]
  breadcrumb -> { 'Surname, Forename' }, -> {  poms_show_path(1) }, only: [:show]

  def index
    response = StaffService.new.get_prisoner_offender_managers(caseload)

    @poms = response.data
  end

  def show; end

  def edit; end
end
