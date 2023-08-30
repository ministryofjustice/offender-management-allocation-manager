# frozen_string_literal: true

module Sorting
  def sort_collection(items, default_sort:, default_direction: :asc)
    field, direction = sort_params(default_sort: default_sort, default_direction: default_direction)
    sort_with_public_send items, field, direction
  end

  def sort_params(default_sort:, default_direction: :asc)
    if params['sort']
      params['sort'].split.map { |s| s.downcase.to_sym }
    else
      [default_sort, default_direction]
    end
  end

private

  def sort_with_public_send(items, field, direction)
    return items if field.nil?
    return items if items.none?
    return items unless items.first.respond_to?(field) # Sometimes the sort field may not be for this set of items

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
end
