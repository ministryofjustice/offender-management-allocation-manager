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

    def calculate_handover_start_date(handover_date:,
                                      category_active_since_date:,
                                      prison_arrival_date:,
                                      is_indeterminate:,
                                      open_prison_rules_apply:,
                                      in_womens_prison:)
      return handover_date unless is_indeterminate && open_prison_rules_apply

      handover_start_date = if in_womens_prison
                              # Women's estate: the day the offender's category changed to "open"
                              category_active_since_date
                            else
                              # Men's estate: the day the offender arrived in the open prison
                              prison_arrival_date
                            end
      if handover_start_date.present? && handover_start_date < handover_date
        handover_start_date
      else
        handover_date
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
