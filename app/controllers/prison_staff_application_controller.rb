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

    if field == :cell_location
      cell_location_sort(allocations, direction)
    elsif field == :pom_responsibility
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
end
