# Fetching a list of offenders from the Elite2 API is something that hapens
# frequently, often then filtered and enriched with local data.  The
# OffenderList class encapsulates this functionality in one place to provide
# some consistency with how it is done.
#
# Usage:
#   # Fetch all offenders for a prison
#   offender_list = OffenderList.new('LEI')
#   offender_list.all
#
module Nomis::Elite2
  class OffenderList
    def initialize(prison, batch_size: 250)
      @prison = prison
      @batch_size = batch_size
      @batch_filters = []
      @enrichment_funcs = []
    end

    def add_batch_filter(func)
      # The Proc provided to this method, will be provided an entire
      # batch of offenders, and is expected to return a list. The returned
      # list will replace the current batch.

      # Multiple filters can be registered and will be run in the order
      # that they were added
      @batch_filters << func
    end

    def fetch
      offenders = []

      (0..number_required_requests).each do |page|
        batch = get_page_of_offenders(page)
        next if batch.empty?

        @batch_filters.each do |filter|
          batch = filter.call(batch)
        end

        offenders += batch
      end

      offenders
    end

  private

    def number_required_requests
      # Fetch the first 1 prisoners just for the total number of pages so that we
      # can send batched queries.
      info_request = OffenderApi.list(@prison, 1, page_size: 1)

      # The maximum number of pages we need to fetch before we have all of
      # the offenders
      @number_required_requests ||= (info_request.meta.total_pages / @batch_size) + 1
    end

    def get_page_of_offenders(page_number)
      # Retrieves a specific page of offenders based on the previously defined
      # batch size (or the default of 250).
      Nomis::Elite2::OffenderApi.list(
        @prison,
        page_number,
        page_size: @batch_size
      ).data
    end
  end
end
