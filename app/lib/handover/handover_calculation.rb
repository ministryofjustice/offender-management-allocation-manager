module Handover::HandoverCalculation
  POM_RESPONSIBLE = CalculatedHandoverDate::CUSTODY_ONLY
  POM_RESPONSIBLE_COM_SUPPORTING = CalculatedHandoverDate::CUSTODY_WITH_COM
  COM_RESPONSIBLE = CalculatedHandoverDate::COMMUNITY_RESPONSIBLE

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
      return handover_date unless is_indeterminate && open_prison_rules_apply

      handover_start_date = if in_womens_prison
                              # Women's estate: the day the offender's category changed to "open"
                              category_active_since_date
                            else
                              # Men's estate: the day the offender arrived in the open prison
                              prison_arrival_date
                            end
      if handover_start_date.present? && handover_date.present? && handover_start_date < handover_date
        handover_start_date
      else
        handover_date
      end
    end

    def calculate_responsibility(handover_date:, handover_start_date:, today: Time.zone.now.utc.to_date)
      return COM_RESPONSIBLE if handover_date.nil?

      raise HandoverCalculationArgumentError, 'handover_start_date must be given' if handover_start_date.nil?

      if handover_start_date > handover_date
        raise HandoverCalculationArgumentError, 'handover_start_date cannot be after handover_date'
      end

      if today < handover_start_date
        POM_RESPONSIBLE
      elsif today < handover_date
        POM_RESPONSIBLE_COM_SUPPORTING
      else
        COM_RESPONSIBLE
      end
    end

    def calculate_earliest_release(is_indeterminate:,
                                   tariff_date:,
                                   target_hearing_date:,
                                   parole_eligibility_date:,
                                   conditional_release_date:,
                                   automatic_release_date:,
                                   today: Time.zone.now.utc.to_date)
      if is_indeterminate
        if tariff_date
          NamedDate[tariff_date, 'TED']
        else
          ped = NamedDate[parole_eligibility_date, 'PED']
          thd = NamedDate[target_hearing_date, 'THD']
          [thd, ped].keep_if { |d| d && d.date > today }.min
        end
      elsif parole_eligibility_date
        NamedDate[parole_eligibility_date, 'PED']
      else
        crd = NamedDate[conditional_release_date, 'CRD']
        ard = NamedDate[automatic_release_date, 'ARD']
        [ard, crd].compact.min
      end
    end
  end
end
