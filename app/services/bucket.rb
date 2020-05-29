# frozen_string_literal: true

class Bucket
  attr_reader :items

  def initialize(sortable_fields)
    @items = []
    @valid_sort_fields = sortable_fields
  end

  def count
    @items.count
  end

  def <<(item)
    @items << item
  end

  def sort(field, direction = :asc)
    return unless @valid_sort_fields.include?(field)

    @items = if field == :earliest_release_date
               @items.sort_by { |e| e.send(field) || Date.new(1) }
             else
               @items.sort_by(&field)
             end

    @items = @items.reverse if direction == :desc
  end
end
