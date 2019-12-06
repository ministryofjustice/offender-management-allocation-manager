# frozen_string_literal: true

class CaseloadController < PrisonsApplicationController
  before_action :ensure_pom
  before_action :load_pom

  breadcrumb -> { 'Your caseload' },
             -> { prison_caseload_index_path(active_prison_id) }
  breadcrumb -> { 'New cases' },
             -> { new_prison_caseload_path(active_prison_id) }, only: [:new]
  breadcrumb -> { 'Cases close to handover' },
             -> { prison_caseload_handover_start_path(active_prison_id) },
             only: [:handover_start]

  def index
    caseload = PomCaseload.new(@pom.staff_id, @prison)

    @new_cases_count = caseload.allocations.count(&:new_case?)
    sorted_allocations = sort_allocations(filter_allocations(caseload.allocations))

    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)

    @total_allocation_count = sorted_allocations.count
    @pending_handover_count = pending_handover_offenders(caseload.allocations.map(&:offender)).count
    @pending_task_count = caseload.tasks_for_offenders.count
  end

  def new
    caseload = PomCaseload.new(@pom.staff_id, @prison)
    @new_cases = sort_allocations(caseload.allocations.select(&:new_case?))
  end

  def handover_start
    offenders = pending_handover_offenders PomCaseload.new(@pom.staff_id, @prison).allocations.map(&:offender)

    @upcoming_handovers = Kaminari.paginate_array(offenders).page(page)
  end

private

  def pending_handover_offenders(allocated_offenders)
    one_month_time = Time.zone.today + 30.days

    upcoming_offenders = allocated_offenders.select { |offender|
      start_date = offender.handover_start_date.first

      start_date.present? &&
      start_date.between?(Time.zone.today, one_month_time)
    }

    upcoming_offenders.map{ |offender|
      responsibility = Responsibility.find_by(nomis_offender_id: offender.offender_no)
      OffenderPresenter.new(offender, responsibility)
    }
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
        a.pom_responsibility == params['role']
      }
    end
    allocations
  end

  def load_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison_id
    )
  end

  def page
    params.fetch('page', 1).to_i
  end
end
