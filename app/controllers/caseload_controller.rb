# frozen_string_literal: true

class CaseloadController < PrisonsApplicationController
  before_action :ensure_pom

  breadcrumb -> { 'Your caseload' },
             -> { prison_caseload_index_path(active_prison) }
  breadcrumb -> { 'New cases' },
             -> { new_prison_caseload_path(active_prison) }, only: [:new]
  breadcrumb -> { 'Cases close to handover' },
             -> { prison_caseload_handover_start_path(active_prison) }, only: [:handover_start]

  def index
    allocations = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )

    @new_cases_count = allocations.select(&:new_case?).count
    allocations = sort_allocations(filter_allocations(allocations))
    @total_allocations = allocations.count
    @allocations = Kaminari.paginate_array(allocations).page(page)
  end

  def new
    @new_cases = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    ).select(&:new_case?)
  end

  def handover_start
    allocations = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )

    @new_cases_count = allocations.select(&:new_case?).count
    allocations = sort_allocations(filter_allocations(allocations))
    @total_allocations = allocations.count
    @upcoming_handovers = Kaminari.paginate_array(allocations).page(page)
  end

private

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

  def filter_allocations(allocations)
    if params['q'].present?
      @q = params['q']
      query = @q.upcase
      allocations = allocations.select { |a|
        a.full_name.upcase.include?(query) || a.nomis_offender_id.include?(query)
      }
    end
    if params['role'].present?
      allocations = allocations.select { |a|
        a.responsibility == params['role']
      }
    end
    allocations
  end

  def ensure_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison
    )

    if @pom.blank?
      redirect_to '/'
    end
  end

  def page
    params.fetch('page', 1).to_i
  end
end
