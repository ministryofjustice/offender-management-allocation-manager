# frozen_string_literal: true

class CaseloadController < PrisonsApplicationController
  before_action :ensure_pom

  breadcrumb -> { 'Your caseload' },
             -> { prison_caseload_index_path(active_prison) }
  breadcrumb -> { 'New cases' },
             -> { new_prison_caseload_path(active_prison) }, only: [:new]
  breadcrumb -> { 'Cases close to handover' },
             -> { prison_caseload_handover_start_path(active_prison) },
             only: [:handover_start]

  def index
    @new_cases_count = all_allocations.select(&:new_case?).count
    sorted_allocations = sort_allocations(filter_allocations(all_allocations))

    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)
    @total_allocation_count = sorted_allocations.count
    @pending_handover_count = pending_handover_count
  end

  def new
    @new_cases = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    ).select(&:new_case?)
  end

  def handover_start
    offenders = pending_handover_offenders
    @upcoming_handovers = Kaminari.paginate_array(offenders).page(page)
  end

private

  def all_allocations
    @all_allocations ||= PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )
  end

  def pending_handover_count
    pending_handover_offenders.count
  end

  def pending_handover_offenders
    ids = Set.new all_allocations.map(&:nomis_offender_id)
    offenders = OffenderService.get_offenders_for_prison(active_prison)
    allocated_offenders = offenders.select { |offender|
      ids.include? offender.offender_no
    }

    one_week_time = Time.zone.today + 7.days

    upcoming_offenders = allocated_offenders.select { |offender|
      start_date = offender.handover_start_date.first

      start_date.present? &&
      start_date.between?(Time.zone.today, one_week_time)
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
