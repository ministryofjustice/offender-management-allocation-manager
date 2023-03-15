class Handover::HandoverCalculation
  class << self
    def calculate_handover_date(sentence_start_date:,
                                earliest_release_date:,
                                is_early_allocation:,
                                is_indeterminate:,
                                in_open_conditions:)
      if is_indeterminate
        [earliest_release_date - 8.months, in_open_conditions ? :indeterminate_open : :indeterminate]
      else
        calculate_determinate_handover_date(sentence_start_date: sentence_start_date,
                                            earliest_release_date: earliest_release_date,
                                            is_early_allocation: is_early_allocation)
      end
    end

  private

    def calculate_determinate_handover_date(sentence_start_date:,
                                            earliest_release_date:,
                                            is_early_allocation:)
      if sentence_start_date + 10.months >= earliest_release_date
        [nil, :determinate_short]
      elsif is_early_allocation
        [earliest_release_date - 15.months, :early_allocation]
      else
        [earliest_release_date - 8.months - 14.days, :determinate]
      end
    end
  end
end
