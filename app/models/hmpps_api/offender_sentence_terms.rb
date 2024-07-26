module HmppsApi
  class OffenderSentenceTerms
    def self.from_payload(payload)
      new(payload.map { |term| HmppsApi::OffenderSentenceTerm.new(term) })
    end

    def initialize(offender_sentence_terms = [])
      @offender_sentence_terms = offender_sentence_terms
    end

    delegate :count, :[], to: :@offender_sentence_terms

    def additional_isp?
      @offender_sentence_terms
        .select(&:indeterminate?)
        .group_by(&:case_id).values
        .map  { |terms| terms.first.sentence_start_date }.sort
        .then { |dates| dates.count > 1 && dates.last > dates.first }
    end
  end
end
