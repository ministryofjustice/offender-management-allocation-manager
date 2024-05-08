module HmppsApi
  class OffenderSentenceTerm
    attr_reader :booking_id,
                :sentence_sequence,
                :term_sequence,
                :sentence_type,
                :sentence_type_description,
                :start_date,
                :days,
                :life_sentence,
                :case_id,
                :sentence_term_code,
                :line_seq,
                :sentence_start_date

    def initialize(payload = {})
      @booking_id = payload['bookingId']
      @case_id = payload['caseId']
      @sentence_sequence = payload['sentenceSequence']
      @line_seq = payload['lineSeq']
      @term_sequence = payload['termSequence']
      @life_sentence = payload['lifeSentence']
      @sentence_type = SentenceType.new(payload['sentenceType'])
      @sentence_type_description = payload['sentenceTypeDescription']
      @sentence_term_code = payload['sentenceTermCode']
      @sentence_start_date = payload['sentenceStartDate']&.to_date
      @start_date = payload['startDate']&.to_date
      @years = payload['years']
      @months = payload['months']
      @days = payload['days']
    end

    def indeterminate? = life_sentence || sentence_type.indeterminate?
  end
end
