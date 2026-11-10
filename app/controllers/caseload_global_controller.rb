# frozen_string_literal: true

class CaseloadGlobalController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_and_validate_pom

  def index
    @allocated = @prison.allocated.map do |offender|
      OffenderWithAllocationPresenter.new(offender, @prison.allocations.detect { |a| a.nomis_offender_id == offender.offender_no })
    end

    @recent_allocations = paginate_array(sort_allocations(recent_allocations))
    @upcoming_releases = paginate_array(sort_allocations(upcoming_releases))
    @all_other_allocations = paginate_array(sort_allocations(caseload_allocations))

    @summary = {
      all_prison_cases: @allocated.count,
      new_cases_count: @pom.allocations.count(&:new_case?),
      total_cases: @pom.allocations.count,
      last_seven_days: @recent_allocations.count,
      release_next_four_weeks: @upcoming_releases.length,
      pending_task_count: @pom.pom_tasks.count,
      parole_cases_count: @pom.allocations.count(&:approaching_parole?)
    }
  end

private

  def caseload_allocations = @allocated

  def recent_allocations
    caseload_allocations.filter do |a|
      a.allocation_date >= 7.days.ago
    end
  end
end
