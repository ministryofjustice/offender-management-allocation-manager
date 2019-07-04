# frozen_string_literal: true

class SearchController < PrisonsApplicationController
  breadcrumb 'Search', -> { prison_search_path(active_prison) }, only: [:search]

  PAGE_SIZE = 10

  def search
    @q = search_term

    offenders = SearchService.search_for_offenders(@q, active_prison)
    total = offenders.count

    @offenders = get_slice_for_page(offenders, page)
    @page_meta = create_page_meta(total, @offenders.count)
  end

private

  def get_slice_for_page(offenders, page_number)
    start = [(page_number - 1) * PAGE_SIZE, 0].max
    slice = offenders.slice(start, PAGE_SIZE)

    # At this point offenders contains ALL of the offenders at the prison that
    # match the search term, slice is the current page worth of offenders.
    # We will only show PAGE_SIZE at a time, so there is no need
    # to get the allocated POM name for offenders, we will just get them
    # for the much smaller slice.
    OffenderService.set_allocated_pom_name(slice, active_prison)
  end

  def create_page_meta(total_records, current_view)
    PageMeta.new.tap{ |p|
      p.size = PAGE_SIZE
      p.total_pages = (total_records / PAGE_SIZE.to_f).ceil
      p.total_elements = total_records
      p.number = page
      p.items_on_page = current_view
    }
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    params['q']
  end
end
