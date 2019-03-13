class SearchController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Search', :search_path, only: [:search]

  def search
    @q = search_term

    offenders = SearchService.search_for_offenders(@q, active_caseload)
    total = offenders.count

    @offenders = get_slice_for_page(offenders, page)
    @page_meta = create_page_meta(total, @offenders.count)
  end

private

  # At this point @offenders contains ALL of the offenders at the prison that
  # match the search term. We will only show 10 at a time, so there is no need
  # to get the allcocated POM name for all of them.
  def get_slice_for_page(offenders, page_number)
    start = [(page_number - 1) * 10, 0].max
    slice = offenders.slice(start, 10)

    OffenderService.set_allocated_pom_name(slice, active_caseload)
    slice
  end

  def create_page_meta(total_records, current_view)
    PageMeta.new.tap{ |p|
      p.size = 10
      p.total_pages = (total_records / 10.0).ceil
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
