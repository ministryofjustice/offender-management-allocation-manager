# frozen_string_literal: true

class SearchService
  # Fetch all of the offenders (for a given prison) filtering
  # out offenders based on the provided text.
  def self.search_for_offenders(text, prison)
    return [] if text.nil?

    search_term = text.upcase

    OffenderService.get_offenders_for_prison(prison).select do |offender|
      offender.last_name.include?(search_term) ||
        offender.first_name.include?(search_term) ||
        offender.offender_no.include?(search_term)
    end
  end
end
