# frozen_string_literal: true

class PageMeta
  include MemoryModel

  attribute :size, :integer
  attribute :total_elements, :integer
  attribute :total_pages, :integer
  attribute :number, :integer
  attribute :items_on_page, :integer

  def record_range
    return '0 - 0' if total_elements == 0

    start = (size * (number - 1)) + 1
    "#{start} - #{start + (items_on_page - 1)}"
  end

  def current_page
    number
  end

  def previous?
    current_page > 1
  end

  def next?
    current_page < total_pages
  end

  def pages
    return [] if total_elements == 0

    page_numbers = [1]

    page_numbers += left_pages
    page_numbers << number unless number == 1
    page_numbers += right_pages

    # Push the last page (unless we have already)
    page_numbers << total_pages unless page_numbers.include?(total_pages)

    page_numbers
  end

private

  def left_pages
    pnums = []
    left = number - 1

    if left > 1
      pnums << nil if left - 1 > 1
      pnums << left
    end

    pnums
  end

  def right_pages
    pnums = []
    right = number + 1

    if right <= total_pages
      pnums << right
      pnums << nil if right + 1 < total_pages
    end

    pnums
  end
end
