class Offenders::Sentences < SimpleDelegator
  def initialize(booking_id:)
    super(
      Sentences.for(booking_id:)
    )
  end

  def single_sentence?
    count == 1
  end

  def duration
    sum(&:duration)
  end

  def sentenced_to_additional_future_isp?
    isp_start_dates = select(&:indeterminate?).map(&:sentence_start_date)
    isp_start_dates.count > 1 && isp_start_dates.last > isp_start_dates.first
  end

  def concurrent_sentence_of_12_months_or_under?
    count > 1 && any? { |sentence| sentence.duration <= 12.months }
  end

  def concurrent_sentence_of_20_months_or_over?
    count > 1 && any? { |sentence| sentence.duration >= 20.months }
  end
end
