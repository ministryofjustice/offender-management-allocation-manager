# frozen_string_literal: true

class CaseloadController < PrisonsApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom

  breadcrumb -> { 'Your caseload' },
             -> { prison_staff_caseload_index_path(active_prison_id, staff_id) }
  breadcrumb -> { 'New cases' },
             -> { new_prison_staff_caseload_path(active_prison_id, staff_id) }, only: [:new]
  breadcrumb -> { 'Cases close to handover' },
             -> { prison_staff_caseload_handover_start_path(active_prison_id, staff_id) },
             only: [:handover_start]

  def index
    allocations = @prison.allocations_for(@pom.staff_id)

    @new_cases_count = allocations.count(&:new_case?)
    sorted_allocations = sort_allocations(filter_allocations(allocations))
    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)
    @total_allocation_count = sorted_allocations.count

    @pending_handover_count = pending_handover_offenders(allocations.map(&:offender)).count
    @pending_task_count = PomTasks.new.for_offenders(allocations.map(&:offender)).count
  end

  def new
    @new_cases = sort_allocations(@prison.allocations_for(@pom.staff_id).select(&:new_case?))
  end

  def handover_start
    offenders = pending_handover_offenders @prison.allocations_for(@pom.staff_id).map(&:offender)

    @upcoming_handovers = Kaminari.paginate_array(offenders).page(page)
  end

private

  def pending_handover_offenders(allocated_offenders)
    one_month_time = Time.zone.today + 30.days

    upcoming_offenders = allocated_offenders.select { |offender|
      start_date = offender.handover_start_date

      start_date.present? &&
      start_date.between?(Time.zone.today, one_month_time)
    }

    upcoming_offenders.map { |offender|
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
    @pom = StaffMember.new(params[:staff_id])
  end

  def ensure_signed_in_pom_is_this_pom
    user = Nomis::Elite2::UserApi.user_details(current_user)
    unless staff_id == user.staff_id || current_user_is_spo?
      redirect_to '/401'
    end
  end

  def page
    params.fetch('page', 1).to_i
  end

  def staff_id
    params[:staff_id].to_i
  end
end
