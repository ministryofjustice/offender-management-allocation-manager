# frozen_string_literal: true

class PrisonStaffApplicationController < PrisonsApplicationController
private

  def load_pom
    @pom = StaffMember.new(@prison, staff_id)
  end

  def ensure_signed_in_pom_is_this_pom
    unless staff_id == @staff_id || current_user_is_spo?
      redirect_to '/401'
    end
  end

  def staff_id
    params.fetch(:staff_id).to_i
  end

  def sort_allocations(allocations)
    field, direction = sort_params(default_sort: :last_name)

    case field
    when :location
      cell_location_sort(allocations, direction)
    when :pom_responsibility
      if direction == :asc
        allocations.sort_by { |a| view_context.pom_responsibility_label(a) }
      else
        allocations.sort { |a, b| view_context.pom_responsibility_label(b) <=> view_context.pom_responsibility_label(a) }
      end
    else
      sort_with_public_send allocations, field, direction
    end
  end

  def cell_location_sort(allocations, direction)
    allocations = allocations.sort do |a, b|
      if a.latest_temp_movement_date.nil? && b.latest_temp_movement_date.nil?
        compare_via_public_send :location, :asc, a, b
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

  def pom_allocations_summary
    @recent_allocations = Kaminari.paginate_array(sort_allocations(filter_allocations(@pom.allocations).filter do |a|
      a.primary_pom_allocated_at.to_date >= 7.days.ago
    end)).page(page)

    @upcoming_releases = Kaminari.paginate_array(sort_allocations(filter_allocations(@pom.allocations).filter do |a|
      a.earliest_release_date.present? &&
        a.earliest_release_date.to_date <= 4.weeks.after && Date.current.beginning_of_day < a.earliest_release_date.to_date
    end)).page(page)

    @allocations = Kaminari.paginate_array(sort_allocations(filter_allocations(@pom.allocations))).page(page)

    @handover_cases = Handover::CategorisedHandoverCasesForPom.new(@pom)

    @summary = {
      all_prison_cases: @prison.allocations.all.count,
      new_cases_count: @pom.allocations.count(&:new_case?),
      total_cases: @pom.allocations.count,
      last_seven_days: @pom.allocations.count { |a| a.primary_pom_allocated_at.to_date >= 7.days.ago },
      release_next_four_weeks: @pom.allocations.count do |a|
        a.earliest_release_date.present? &&
          a.earliest_release_date.to_date <= 4.weeks.after && Date.current.beginning_of_day < a.earliest_release_date.to_date
      end,
      pending_handover_count: @handover_cases.upcoming.count,
      pending_task_count: PomTasks.new.for_offenders(@pom.allocations).count,
      last_allocated_date: @allocations.max_by(&:primary_pom_allocated_at)&.primary_pom_allocated_at&.to_date
    }
  end

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
