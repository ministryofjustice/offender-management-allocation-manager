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
    set_allocated_pom_names(slice, active_prison_id)
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    # defaults to an empty string if the key 'q' can't be found
    params.fetch('q', '').strip
  end

  # Takes a list of OffenderSummary or Offender objects, and returns them with their
  # allocated POM name set in :allocated_pom_name.
  def set_allocated_pom_names(offenders, prison_id)
    pom_names = PrisonOffenderManagerService.get_pom_names(prison_id)
    nomis_offender_ids = offenders.map(&:offender_no)
    offender_to_staff_hash = Allocation.
      where(nomis_offender_id: nomis_offender_ids).
      map { |a|
        [
          a.nomis_offender_id,
          {
            pom_name: pom_names[a.primary_pom_nomis_id],
            allocation_date: (a.primary_pom_allocated_at || a.updated_at)&.to_date
          }
        ]
      }.to_h

    offenders.each do |offender|
      if offender_to_staff_hash.key?(offender.offender_no)
        offender.allocated_pom_name = offender_to_staff_hash[offender.offender_no][:pom_name]
        offender.allocation_date = offender_to_staff_hash[offender.offender_no][:allocation_date]
      end
    end
    offenders
  end
end
