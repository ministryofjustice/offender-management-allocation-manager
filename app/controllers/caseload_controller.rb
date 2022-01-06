# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom

  before_action do
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
    data = case @filter
           when 'recent_allocations'
             filter_allocations(@pom.allocations).filter { |a|
               a.primary_pom_allocated_at.to_date >= 7.days.ago
             }
           when 'upcoming_releases'
             filter_allocations(@pom.allocations).filter { |a|
               a.earliest_release_date.to_date >= 4.weeks.after &&
                 Date.current.beginning_of_day > a.earliest_release_date.to_date
             }
           else
             filter_allocations(@pom.allocations)
           end

    @allocations = Kaminari.paginate_array(sort_allocations(data)).page(page)
  end

  def new_cases
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
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
