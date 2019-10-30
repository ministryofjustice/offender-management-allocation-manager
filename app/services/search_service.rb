# frozen_string_literal: true

class SearchService
  # Fetch all of the offenders (for a given prison) filtering
  # out offenders based on the provided text.
  def self.search_for_offenders(text, prison)
    return [] if text.nil?

    search_term = text.upcase

    prison.offenders.select do |offender|
      offender.last_name.start_with?(search_term) ||
        offender.first_name.start_with?(search_term) ||
        offender.offender_no.include?(search_term)
    end
  end
end
