module HmppsApi
  class OffenderSentenceTerms
    def self.from_payload(payload)
      new(payload.map { |term| HmppsApi::OffenderSentenceTerm.new(term) })
    end

    def initialize(offender_sentence_terms = [])
      @offender_sentence_terms = offender_sentence_terms
    end

    delegate :count, :[], to: :@offender_sentence_terms

    def has_additional_isp?
      @offender_sentence_terms.select(&:indeterminate?)
        .group_by(&:case_id).values
        .map  { |terms| terms.first.sentence_start_date }.sort
        .then { |dates| dates.count > 1 && dates.last > dates.first }
    end

    def has_concurrent_sentence_of_12_months_or_under?
      cases = @offender_sentence_terms
        .group_by(&:case_id)
        .values
        .map(&:first)
      cases.count > 1 && cases.any? { |term| term.duration < 12.months }
    end
  end
end
