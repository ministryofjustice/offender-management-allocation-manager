# frozen_string_literal: true

class SearchService
  # filter out offenders based on the provided text.
  def self.search_for_offenders(text, offenders)
    return [] if text.nil?

    search_term = text.upcase

    offenders.select do |offender|
      offender.last_name.upcase.start_with?(search_term) ||
        offender.first_name.upcase.start_with?(search_term) ||
        offender.offender_no.include?(search_term)
    end
  end
end
