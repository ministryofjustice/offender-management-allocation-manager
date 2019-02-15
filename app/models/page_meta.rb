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

  def page_count
    total_pages
  end

  def page_numbers
    page = current_page

    return [] if total_pages == 0

    return 1..[total_pages, 5].min if page <= 3

    return total_pages - 5..total_pages if page >= total_pages - 5

    page - 2..page + 2
  end

  def previous?
    current_page > 1
  end

  def next?
    current_page < total_pages
  end
end
