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
    @errors = {}
  end

  # rubocop:disable Metrics/MethodLength
  def update
    @pom = PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])

    pom_detail = PrisonOffenderManagerService.update_pom(
      nomis_staff_id: params[:nomis_staff_id].to_i,
      working_pattern: working_pattern,
      status: edit_pom_params[:status]
    )

    if pom_detail.valid?
      redirect_to pom_path(id: @pom.staff_id)
      return
    end

    update_record_for_errors(pom_detail)
    render :edit
  end
# rubocop:enable Metrics/MethodLength

private

  def update_record_for_errors(pom_detail)
    @pom.working_pattern = working_pattern
    @pom.status = edit_pom_params[:status]
    @errors = pom_detail.errors
  end

  def working_pattern
    return '1.0' if edit_pom_params[:description] == 'FT'

    edit_pom_params[:working_pattern]
  end

  def pom
    PrisonOffenderManagerService.get_pom(active_caseload, params[:nomis_staff_id])
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status, :description)
  end
end
