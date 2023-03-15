class Handover::HandoverCalculation
  class << self
    def calculate_handover_date(sentence_start_date:,
                                earliest_release_date:,
                                is_determinate:)
      raise NotImplementedError unless is_determinate

      if sentence_start_date + 10.months >= earliest_release_date
        [nil, :determinate_short]
      else
        [earliest_release_date - 8.months - 14.days, :determinate]
      end
    end
  end
end
