module HmppsApi
  class OffenderSentenceTerms
    def self.from_payload(payload)
      new(payload.map { |term| HmppsApi::OffenderSentenceTerm.new(term) })
    end

    def initialize(offender_sentence_terms = [])
      @sentences = Sentences.new(offender_sentence_terms)
      @isp_sentences = Sentences.new(offender_sentence_terms.select(&:indeterminate?))
    end

    delegate :count, :[], to: :@offender_sentence_terms

    def has_additional_isp?
      isp_sentences.multiple? && isp_sentences.earliest_start_dates.sort.then { |dates| dates.last > dates.first }
    end

    def has_concurrent_sentence_of_12_months_or_under?
      sentences.multiple? && sentences.any_with_term? { |term| term.duration < 12.months }
    end

    def has_concurrent_sentence_of_20_months_or_over?
      sentences.multiple? && sentences.any_with_term? { |term| term.duration >= 20.months }
    end

  private

    attr_reader :sentences, :isp_sentences

    class Sentences
      def initialize(offender_sentence_terms = [])
        @sentence_terms = offender_sentence_terms.group_by(&:case_id)
      end

      def multiple?
        @sentence_terms.count > 1
      end

      def earliest_start_dates
        @sentence_terms.values.map { |terms| terms.map(&:sentence_start_date).min }
      end

      def any_with_term?(&block)
        @sentence_terms.values.any? do |terms_for_case|
          terms_for_case.any?(&block)
        end
      end
    end
  end
end
