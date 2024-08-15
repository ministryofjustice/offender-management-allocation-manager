class Offenders::Sentences
  def initialize(booking_id:)
    @booking_id = booking_id
  end

  def single_sentence?
    sentences.count == 1
  end

  def multiple_indeterminate_sentences?
    sentences.select(&:indeterminate?).count > 1
  end

  def concurrent_sentence_of_12_months_or_under?
    sentences.count > 1 && sentences.any? { |sentence| sentence.duration <= 12.months }
  end

  def concurrent_sentence_of_20_months_or_over?
    sentences.count > 1 && sentences.any? { |sentence| sentence.duration >= 20.months }
  end

private

  def sentences
    @sentences ||= Sentences.for(booking_id: @booking_id)
  end
end
