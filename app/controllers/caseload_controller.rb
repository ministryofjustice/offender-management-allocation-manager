# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  include Sorting

  def index
    allocations = @pom.allocations

    @new_cases_count = allocations.count(&:new_case?)
    sorted_allocations = sort_allocations(filter_allocations(allocations))
    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)
    @total_allocation_count = sorted_allocations.count

    @pending_handover_count = @pom.pending_handover_offenders.count
    @pending_task_count = PomTasks.new.for_offenders(allocations.map(&:offender)).count
  end

  def new
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
  end

private

  def sort_allocations(allocations)
    sort_collection(allocations, default_sort: :last_name)
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
end
