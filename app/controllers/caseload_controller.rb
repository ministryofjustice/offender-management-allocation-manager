# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  include Sorting

  def index
    allocations = @pom.allocations

    @new_cases_count = allocations.count(&:new_case?)
    sorted_allocations = sort_allocations(filter_allocations(allocations))
    @allocations = Kaminari.paginate_array(sorted_allocations).page(page)

    @pending_handover_count = @pom.pending_handover_offenders.count
    @pending_task_count = PomTasks.new.for_offenders(allocations).count
  end

  def new_cases
    @new_cases = sort_allocations(@pom.allocations.select(&:new_case?))
  end

private

  def sort_allocations(allocations)
    field, direction = sort_params(default_sort: :last_name)

    if field == :cell_location
      cell_location_sort(allocations, direction)
    else
      sort_with_public_send allocations, field, direction
    end
  end

  def cell_location_sort(allocations, direction)
    allocations = allocations.sort do |a, b|
      if a.latest_temp_movement_date.nil? && b.latest_temp_movement_date.nil?
        compare_via_public_send :cell_location, :asc, a, b
      elsif a.latest_temp_movement_date.nil? && b.latest_temp_movement_date.present?
        1
      elsif a.latest_temp_movement_date.present? && b.latest_temp_movement_date.nil?
        -1
      else
        a.latest_temp_movement_date <=> b.latest_temp_movement_date
      end
    end

    allocations.reverse! if direction == :desc
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
end
