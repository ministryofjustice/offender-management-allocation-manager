# frozen_string_literal: true

class CaseloadGlobalController < CaseloadController
  def index
    @allocated = @prison.allocated.map do |offender|
      OffenderWithAllocationPresenter.new(offender, @prison.allocations.detect { |a| a.nomis_offender_id == offender.offender_no })
    end

    @total_cases = @allocated.count

    @recent_allocations = Kaminari.paginate_array(sort_allocations(filter_allocations(@allocated).filter do |a|
      a.allocation_date >= 7.days.ago
    end)).page(page)

    @upcoming_releases = Kaminari.paginate_array(sort_allocations(filter_allocations(@allocated)).filter do |a|
      a.earliest_release_date.present? &&
        a.earliest_release_date.to_date <= 4.weeks.after && Date.current.beginning_of_day < a.earliest_release_date.to_date
    end).page(page)

    @all_other_allocations = Kaminari.paginate_array(sort_allocations(filter_allocations(@allocated))).page(page)

    @summary = {
      all_prison_cases: @allocated.count,
      new_cases_count: @pom.allocations.count(&:new_case?),
      total_cases: @pom.allocations.count,
      last_seven_days: @recent_allocations.count,
      release_next_four_weeks: @upcoming_releases.length,
      pending_task_count: @pom.pom_tasks.count,
      parole_cases_count: @pom.allocations.select(&:approaching_parole?).size
    }
  end

private

  def filter_allocations(allocations)
    if params['q'].present?
      query = params['q'].upcase
      allocations = allocations.select do |a|
        a.full_name.upcase.include?(query) || a.offender_no.include?(query)
      end
    end
    allocations
  end
end
