# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom, :pom_allocations_summary

  def cases; end

  def new_cases
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
  end

  def updates_required
    sorted_tasks = PomTasks.new.for_offenders(@current_user.allocations)
    @pom_tasks = Kaminari.paginate_array(sorted_tasks).page(page)
  end
end
