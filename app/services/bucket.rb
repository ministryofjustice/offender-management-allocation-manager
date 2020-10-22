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

  def sort_bucket!(field, direction = :asc)
    return unless @valid_sort_fields.include?(field)

    if field == :earliest_release_date
      @items.sort_by! { |e| e.public_send(field) || Date.new(1) }
    else
      @items.sort_by!(&field)
    end

    @items.reverse! if direction == :desc
  end
end
