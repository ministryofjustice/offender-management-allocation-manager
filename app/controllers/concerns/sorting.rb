# frozen_string_literal: true

module Sorting
  SORTABLE_FIELDS = %i[
    action_label
    additional_information
    allocated_com_name
    allocated_pom_role
    allocation_date
    awaiting_allocation_for
    case_owner
    com_allocation_days_overdue
    complexity_level_number
    coworking_allocations_count
    earliest_release_date
    formatted_pom_name
    handover_date
    last_name
    location
    new_allocations_count
    next_parole_date
    offender_last_name
    offender_name
    pom_responsibility
    position
    primary_pom_allocated_at
    responsible_allocations_count
    staff_member_full_name_ordered
    supporting_allocations_count
    tier
    total_allocations_count
    working_pattern
  ].freeze

  def sort_collection(items, default_sort:, default_direction: :asc)
    field, direction = sort_params(default_sort: default_sort, default_direction: default_direction)
    sort_with_public_send items, field, direction
  end

  def sort_and_paginate(collection, default_sort: :handover_date, default_direction: :asc)
    sorted_collection = sort_collection(collection, default_sort:, default_direction:)
    paginate_array(sorted_collection)
  end

  def paginate_array(collection)
    Kaminari.paginate_array(collection).page(page)
  end

private

  def sort_with_public_send(items, field, direction)
    return items if SORTABLE_FIELDS.exclude?(field)

    items.sort do |x, y|
      compare_via_public_send field, direction, x, y
    end
  end

  def compare_via_public_send(field, direction, item1, item2)
    if direction != :desc
      a = item1.public_send(field)
      b = item2.public_send(field)
    else
      b = item1.public_send(field)
      a = item2.public_send(field)
    end
    # ensure that nil values sort low, but other values sort by comparison
    if a.present? && b.present?
      a <=> b
    elsif a.nil?
      -1
    else
      1
    end
  end

  def sort_params(default_sort:, default_direction: :asc)
    if params['sort']
      params['sort'].split.map { |s| s.downcase.to_sym }
    else
      [default_sort, default_direction]
    end
  end

  def page
    params.fetch('page', 1).to_i
  end
end
