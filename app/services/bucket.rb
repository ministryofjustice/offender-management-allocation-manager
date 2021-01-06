# frozen_string_literal: true

class Bucket
  include Enumerable

  def initialize(sortable_fields)
    @items = []
    @valid_sort_fields = sortable_fields
  end

  def each
    @items.each { |item| yield item }
  end

  def <<(item)
    @items << item
  end

  def sort_bucket!(field, direction)
    return unless @valid_sort_fields.include?(field)

    @items.sort! do |x, y|
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
