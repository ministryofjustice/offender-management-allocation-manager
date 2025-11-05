module Handover::HandoverCalculation
  class << self
    def calculate_handover_date(sentence_start_date:,
                                earliest_release_date:,
                                is_determinate_parole:,
                                is_early_allocation:,
                                is_indeterminate:,
                                in_open_conditions:)
      if is_early_allocation
        [earliest_release_date - 15.months, :early_allocation]
      elsif is_indeterminate
        [(earliest_release_date - 12.months if earliest_release_date), in_open_conditions ? :indeterminate_open : :indeterminate]
      elsif sentence_start_date + 10.months >= earliest_release_date
        [nil, :determinate_short]
      elsif is_determinate_parole
        [earliest_release_date - 12.months, :determinate_parole]
      else
        [earliest_release_date - 8.months - 14.days, :determinate]
      end
    end

    def calculate_handover_start_date(handover_date:,
                                      category_active_since_date:,
                                      prison_arrival_date:,
                                      is_indeterminate:,
                                      open_prison_rules_apply:,
                                      in_womens_prison:)
      if is_indeterminate && open_prison_rules_apply
        # Women's estate: the day the offender's category changed to "open"
        # Men's estate: the day the offender arrived in the open prison
        handover_start_date = in_womens_prison ? category_active_since_date : prison_arrival_date

        [handover_start_date, handover_date].compact.min
      else
        handover_date
      end
    end

    def calculate_responsibility(handover_date:, handover_start_date:, today: Time.zone.now.utc.to_date)
      if handover_date.nil?
        CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
      elsif today < handover_start_date
        CalculatedHandoverDate::CUSTODY_ONLY
      elsif today < handover_date
        CalculatedHandoverDate::CUSTODY_WITH_COM
      else
        CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
      end
    end

    def calculate_earliest_release(is_indeterminate:,
                                   tariff_date:,
                                   target_hearing_date:,
                                   parole_eligibility_date:,
                                   conditional_release_date:,
                                   automatic_release_date:)
      if is_indeterminate
        ted = NamedDate[tariff_date, 'TED']
        thd = NamedDate[target_hearing_date, 'THD']

        # get the date which is in the future, prioritising TED
        return ted if ted&.future?
        return thd if thd&.future?

        # revert to the next closest date, or nil
        [ted, thd].compact.min_by { |date| (date.date.to_date - Time.zone.today).abs }
      else
        ped = NamedDate[parole_eligibility_date, 'PED']
        crd = NamedDate[conditional_release_date, 'CRD']
        ard = NamedDate[automatic_release_date, 'ARD']

        ped || [ard, crd].compact.min
      end
    end
  end
end
