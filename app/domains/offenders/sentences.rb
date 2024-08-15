class Offenders::Sentences
  def initialize(booking_id:)
    @booking_id = booking_id
  end

  def single_sentence?
    sentences.count == 1
  end

  def sentenced_to_additional_future_isp?
    isp_start_dates = sentences.select(&:indeterminate?).map(&:sentence_start_date)
    isp_start_dates.count > 1 && isp_start_dates.last > isp_start_dates.first
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
