class SearchService
  FETCH_SIZE = 200

  # Fetch all of the offenders (for a given prison) filtering
  # out offenders based on the provided text.
  # rubocop:disable Metrics/MethodLength
  def self.search_for_offenders(text, prison)
    number_of_requests = max_requests_count(prison)
    tier_map = CaseInformationService.get_case_information(prison)

    search_term = text.upcase
    search_results = []

    (0..number_of_requests).each do |request_no|
      offenders = OffenderService.get_offenders_for_prison(
        prison,
        page_number: request_no,
        page_size: FETCH_SIZE,
        tier_map: tier_map
      )
      break if offenders.blank?

      new_offenders = offenders.select { |offender|
        offender.last_name.start_with?(search_term) ||
        offender.first_name.start_with?(search_term) ||
        offender.offender_no.include?(search_term)
      }
      next if new_offenders.blank?

      search_results += new_offenders
    end

    search_results
  end
# rubocop:enable Metrics/MethodLength

private

  def self.max_requests_count(prison)
    # Fetch the first 1 prisoners just for the total number of pages so that we
    # can send batched queries.
    info_request = Nomis::Elite2::OffenderApi.list(prison, 1, page_size: 1)

    # The maximum number of pages we need to fetch before we have all of
    # the offenders
    (info_request.meta.total_pages / FETCH_SIZE) + 1
  end
end
