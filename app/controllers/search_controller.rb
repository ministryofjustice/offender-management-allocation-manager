# frozen_string_literal: true

class SearchController < PrisonsApplicationController
  def search
    # Users who are not SPOs should not be able to action any of these search results,
    # and instead they should be redirected to the caseload search instead. If a user
    # is both SPO _and_ POM then we'll let them do an actionable search.
    unless current_user_is_spo?
      redirect_to(prison_staff_caseload_index_path(active_prison_id, @staff_id, q: search_term)) && return
    end

    @q = search_term
    offenders = SearchService.search_for_offenders(@q, @prison)
    @offenders = get_slice_for_page(offenders)

    MetricsService.instance.increment_search_count
  end

private

  def get_slice_for_page(offenders)
    slice = Kaminari.paginate_array(offenders).page(page)

    # At this point offenders contains ALL of the offenders at the prison that
    # match the search term, slice is the current page worth of offenders.
    # We will only show PAGE_SIZE at a time, so there is no need
    # to get the allocated POM name for offenders, we will just get them
    # for the much smaller slice.
    OffenderService.set_allocated_pom_name(slice, active_prison_id)
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    # defaults to an empty string if the key 'q' can't be found
    params.fetch('q', '').strip
  end
end
