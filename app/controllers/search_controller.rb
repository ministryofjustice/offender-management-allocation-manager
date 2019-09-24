# frozen_string_literal: true

class SearchController < PrisonsApplicationController
  breadcrumb 'Search', -> { prison_search_path(active_prison) }, only: [:search]

  def search
    @q = search_term

    offenders = SearchService.search_for_offenders(@q, active_prison)

    @offenders = get_slice_for_page(offenders)
  end

private

  def get_slice_for_page(offenders)
    slice = Kaminari.paginate_array(offenders).page(page)

    # At this point offenders contains ALL of the offenders at the prison that
    # match the search term, slice is the current page worth of offenders.
    # We will only show PAGE_SIZE at a time, so there is no need
    # to get the allocated POM name for offenders, we will just get them
    # for the much smaller slice.
    OffenderService.set_allocated_pom_name(slice, active_prison)
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    params['q']
  end
end
