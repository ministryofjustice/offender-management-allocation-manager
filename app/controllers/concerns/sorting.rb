# frozen_string_literal: true

module Sorting
  def sort_collection(items, default_sort:, default_direction: :asc)
    field, direction = sort_params(default_sort, default_direction)
    sort_with_public_send items, field, direction
  end

  def sort_params(default_sort, default_direction = :asc)
    if params['sort']
      params['sort'].split.map { |s| s.downcase.to_sym }
    else
      [default_sort, default_direction]
    end
  end

private

  def sort_with_public_send(items, field, direction)
    items.sort do |x, y|
      if direction == :asc
        a = x.public_send(field)
        b = y.public_send(field)
      else
        b = x.public_send(field)
        a = y.public_send(field)
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
end
