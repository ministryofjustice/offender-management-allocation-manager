# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom, :load_summary
  CASELOAD_FILTERS = %w[all, upcoming_releases, recent_allocation]

  def load_summary
    @filter = params['f'].presence || 'all'
    @summary = {
      all_prison_cases: @prison.allocations.all.count,
      new_cases_count: @pom.allocations.count(&:new_case?),
      total_cases: @pom.allocations.count,
      last_seven_days: @pom.allocations.count { |a| a.primary_pom_allocated_at.to_date >= 7.days.ago },
      release_next_four_weeks: @pom.allocations.count { |a|
        a.earliest_release_date.to_date >= 4.weeks.after && Date.current.beginning_of_day > a.earliest_release_date.to_date
      },
      pending_handover_count: @pom.allocations.count(&:approaching_handover?),
      pending_task_count: PomTasks.new.for_offenders(@pom.allocations).count
    }
  end

  def cases
    @filter = (params['f'].present? && params['f'].in?(CASELOAD_FILTERS)) ? params['f'] : 'all'
    @allocations = Kaminari.paginate_array(sort_allocations(filter_allocations(@pom.allocations))).page(page)
    @recent_allocations = Kaminari.paginate_array(filter_allocations(@pom.allocations).filter { |a|
      a.primary_pom_allocated_at.to_date >= 7.days.ago
    })
    @upcoming_releases = Kaminari.paginate_array(filter_allocations(@pom.allocations).filter { |a|
      a.earliest_release_date.to_date <= 4.weeks.after &&
        Date.current.beginning_of_day < a.earliest_release_date.to_date
    }).page(page)
  end

  def new_cases
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
  end

  def updates_required
    sorted_tasks = PomTasks.new.for_offenders(@current_user.allocations)
    @pom_tasks = Kaminari.paginate_array(sorted_tasks).page(page)
  end

private

  def filter_allocations(allocations)
    if params['q'].present?
      @q = params['q']
      query = @q.upcase
      allocations = allocations.select do |a|
        a.full_name.upcase.include?(query) || a.nomis_offender_id.include?(query)
      end
    end
    if params['role'].present?
      allocations = allocations.select do |a|
        view_context.pom_responsibility_label(a) == params['role']
      end
    end
    allocations
  end
end
