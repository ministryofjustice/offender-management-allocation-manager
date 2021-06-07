# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom

  def index
    @new_cases_count = @pom.allocations.count(&:new_case?)
    sorted_allocations = sort_allocations(filter_allocations(@pom.allocations))
    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)

    @pending_handover_count = @pom.allocations.count(&:approaching_handover?)
    @pending_task_count = PomTasks.new.for_offenders(@pom.allocations).count
  end

  def new_cases
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
  end

private

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
        view_context.pom_responsibility_label(a) == params['role']
      }
    end
    allocations
  end
end
