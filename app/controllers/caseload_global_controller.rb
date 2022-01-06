# frozen_string_literal: true

class CaseloadGlobalController < CaseloadController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom

  def index
    @allocated = @prison.allocated.map do |offender|
      OffenderWithAllocationPresenter.new(offender, @prison.allocations.detect { |a| a.nomis_offender_id == offender.offender_no })
    end

    @summary = {
      all_prison_cases: @allocated.count,
      new_cases_count: @pom.allocations.count(&:new_case?),
      total_cases: @pom.allocations.count,
      last_seven_days: @allocated.count { |a| a.allocation_date.to_date >= 7.days.ago },
      release_next_four_weeks: @allocated.count { |a|
        a.earliest_release_date.to_date >= 4.weeks.after && Date.current.beginning_of_day > a.earliest_release_date.to_date
      },
      pending_handover_count: @pom.allocations.count(&:approaching_handover?),
      pending_task_count: PomTasks.new.for_offenders(@pom.allocations).count
    }

    @total_cases = @allocated.count
    @filter = params['f'].presence || 'all'

    data = case @filter
           when 'recent_allocations'
             filter_allocations(@allocated).filter { |a|
               a.allocation_date >= 7.days.ago
             }
           when 'upcoming_releases'
             filter_allocations(@allocated).filter { |a|
               a.earliest_release_date.to_date >= 4.weeks.after &&
                 Date.current.beginning_of_day > a.earliest_release_date.to_date
             }
           else
             filter_allocations(@allocated)
           end

    @allocations = Kaminari.paginate_array(sort_allocations(data)).page(page)
  end
end
