# frozen_string_literal: true

class HandoverDateService
  HandoverData = Struct.new :start_date, :handover_date, :reason

  # if COM responsible, then handover dates all empty
  NO_HANDOVER_DATE = HandoverData.new nil, nil, 'COM Responsibility'

  def self.handover(offender)
    if offender.recalled?
      HandoverData.new nil, nil, 'Recall case - no handover date calculation'
    elsif offender.nps_case? && offender.indeterminate_sentence? && offender.tariff_date.nil?
      HandoverData.new nil, nil, 'No earliest release date'
    elsif offender.nps_case? || offender.indeterminate_sentence?
      date, reason = nps_handover_date(offender)
      HandoverData.new nps_start_date(offender), date, reason
    else
      crc_date = crc_handover_date(offender)
      HandoverData.new crc_date, crc_date, 'CRC Case'
    end
  end

private

  def self.nps_start_date(offender)
    if offender.early_allocation?
      early_allocation_handover_start_date(offender)
    elsif offender.indeterminate_sentence?
      indeterminate_sentence_handover_start_date(offender)
    else
      determinate_sentence_handover_start_date(offender)
    end
  end

  def self.early_allocation_handover_start_date(offender)
    return nil if offender.conditional_release_date.nil?

    offender.conditional_release_date - 18.months
  end

  def self.indeterminate_sentence_handover_start_date(offender)
    return nil if offender.tariff_date.nil?

    offender.tariff_date - 8.months
  end

  def self.determinate_sentence_handover_start_date(offender)
    if offender.parole_eligibility_date.present?
      offender.parole_eligibility_date - 8.months
    elsif offender.conditional_release_date.present? || offender.automatic_release_date.present?
      earliest_release_date = [
        offender.conditional_release_date,
        offender.automatic_release_date
      ].compact.min

      earliest_release_date - (7.months + 15.days)
    end
  end

  def self.crc_handover_date(offender)
    date = offender.home_detention_curfew_actual_date.presence ||
      offender.home_detention_curfew_eligibility_date.presence ||
             [offender.conditional_release_date,
              offender.automatic_release_date
             ].compact.min
    date - 12.weeks if date
  end

  def self.nps_handover_date(offender)
    if offender.early_allocation?
      return [early_allocation_handover_date(offender), 'NPS Early']
    end

    if offender.indeterminate_sentence?
      [indeterminate_responsibility_date(offender), 'NPS Inderminate']
    elsif offender.parole_eligibility_date.present?
      [offender.parole_eligibility_date - 8.months, 'NPS Determinate Parole Case']
    elsif offender.mappa_level.blank?
      [mappa1_responsibility_date(offender), 'NPS - MAPPA level unknown']
    elsif offender.mappa_level.in? [1, 0]
      [mappa1_responsibility_date(offender), 'NPS Determinate Mappa 1/N']
    else
      [mappa_23_responsibility_date(offender), 'NPS Determinate Mappa 2/3']
    end
  end

  # We can not calculate the handover date for NPS Indeterminate
  # with parole cases where the TED is in the past as we need
  # the parole board decision which currently is not available to us.
  def self.indeterminate_responsibility_date(offender)
    [
      offender.parole_eligibility_date,
      offender.tariff_date
    ].compact.map { |date| date - 8.months }.min
  end

  def self.mappa_23_responsibility_date(offender)
    earliest_date = [
      offender.conditional_release_date,
      offender.automatic_release_date
    ].compact.map { |date| date - (7.months + 15.days) }.min

    [Time.zone.today, earliest_date].compact.max
  end

  # There are a couple of places where we need .5 of a month - which
  # we have assumed 15.days is a reasonable compromise implementation
  def self.mappa1_responsibility_date(offender)
    if offender.home_detention_curfew_actual_date.present?
      offender.home_detention_curfew_actual_date
    else
      earliest_date = [
        offender.conditional_release_date,
        offender.automatic_release_date
      ].compact.map { |date| date - (4.months + 15.days) }.min

      [earliest_date, offender.home_detention_curfew_eligibility_date].compact.min
    end
  end

  def self.early_allocation_handover_date(offender)
    offender.conditional_release_date - 15.months
  end
end
