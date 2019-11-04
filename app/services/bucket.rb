# frozen_string_literal: true

# The Bucket class is a simple data structure that can contain a fixed
# number of things. The initial capacity of the bucket is set on
# creation and once full, any attempts to put more items in the
# bucket will be ignored.
#
# This would just be an array apart from the handling of the last
# N items, and it's recommended not to subclass core classes
class Bucket
  attr_accessor :items
  attr_reader :label

  def initialize(sortable_fields)
    @items = []
    @valid_sort_fields = sortable_fields || default_sortable_fields
  end

  def count
    @items.count
  end

  def <<(item)
    @items << item
  end

  def sort(field, direction = :asc)
    return unless @valid_sort_fields.include?(field)

    if field == :earliest_release_date
      @items = @items.sort_by { |e| e.send(field) || Date.new(1) }
    else
      @items = @items.sort_by(&field)
    end

    @items = @items.reverse if direction == :desc
  end

  def default_sortable_fields
    [:last_name, :earliest_release_date, :awaiting_allocation_for, :tier]
  end
end
