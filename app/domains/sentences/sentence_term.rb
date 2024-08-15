# Represents the raw data that comes from the PrisonAPI for offenderSentenceTerms
class Sentences::SentenceTerm
  attr_reader :booking_id,
              :sentence_sequence,
              :term_sequence,
              :sentence_type,
              :sentence_type_description,
              :start_date,
              :days,
              :months,
              :years,
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
    @years = payload['years'].to_i
    @months = payload['months'].to_i
    @days = payload['days'].to_i
  end

  def indeterminate? = life_sentence || sentence_type.indeterminate?
  def duration = years.years + months.months + days.days
  def <=>(other) = sortable_fields <=> other.sortable_fields
  def sortable_fields = [sentence_start_date, case_id, sentence_sequence, term_sequence]
  def comparable_fields = [sentence_start_date, case_id, sentence_sequence, term_sequence, line_seq]
end
