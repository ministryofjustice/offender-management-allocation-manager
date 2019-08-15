# frozen_string_literal: true

class PomsController < PrisonsApplicationController
  breadcrumb 'Prison Offender Managers',
             -> { prison_poms_path(active_prison) }, only: [:index, :show]
  breadcrumb -> { pom.full_name },
             -> { prison_poms_path(active_prison, params[:nomis_staff_id]) },
             only: [:show]

  def index
    poms = PrisonOffenderManagerService.get_poms(active_prison)
    @active_poms, @inactive_poms = poms.partition { |pom|
      %w[active unavailable].include? pom.status
    }
  end

  def show
    @pom = pom
    @allocations = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )
    @allocations = sort_allocations(@allocations)
  end

  def sort_allocations(allocations)
    if params['sort'].present?
      sort_field, sort_direction = params['sort'].split.map(&:to_sym)
    else
      sort_field = :last_name
      sort_direction = :asc
    end

    # cope with nil values by sorting using to_s - only dates and strings in these fields
    allocations = allocations.sort_by { |sentence| sentence.public_send(sort_field).to_s }
    allocations.reverse! if sort_direction == :desc

    allocations
  end

  def edit
    @pom = PrisonOffenderManagerService.get_pom(active_prison, params[:nomis_staff_id])
    @errors = {}
  end

  def update
    @pom = PrisonOffenderManagerService.get_pom(active_prison, params[:nomis_staff_id])

    pom_detail = PrisonOffenderManagerService.update_pom(
      nomis_staff_id: params[:nomis_staff_id].to_i,
      working_pattern: working_pattern,
      status: edit_pom_params[:status]
    )

    if pom_detail.valid?
      redirect_to prison_pom_path(active_prison, id: @pom.staff_id)
      return
    end

    update_record_for_errors(pom_detail)
    render :edit
  end

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
    PrisonOffenderManagerService.get_pom(active_prison, params[:nomis_staff_id])
  end

  def edit_pom_params
    params.require(:edit_pom).permit(:working_pattern, :status, :description)
  end
end
