# frozen_string_literal: true

HandoverData = Struct.new(:nps_case?,
                          :early_allocation?,
                          :mappa_level,
                          :indeterminate_sentence?) do
  def self.from_offender(offender)
    new(offender.nps_case?,
        offender.early_allocation?,
        offender.mappa_level,
        offender.indeterminate_sentence?)
  end
end

class HandoverDateService
  # rubocop:disable Metrics/LineLength
  def self.handover_start_date(subject, dates)
    return [nil, 'No earliest release date'] if dates.try(:earliest_release_date).nil?

    if subject.nps_case? && !subject.early_allocation?
      return [dates.earliest_release_date - 8.months, 'NPS Indeterminate'] if subject.indeterminate_sentence?

      [dates.earliest_release_date - (7.months + 15.days), 'NPS Determinate']
    else
      [nil, 'CRC or Early Allocation']
    end
  end
  # rubocop:enable Metrics/LineLength

  def self.responsibility_handover_date(subject, dates)
    return [nil, 'No earliest release date'] if dates.try(:earliest_release_date).nil?

    if subject.nps_case?
      nps_handover_date(subject, dates)
    else
      [crc_handover_date(dates), 'CRC']
    end
  end

private

  def self.crc_handover_date(dates)
    [
      dates.home_detention_curfew_eligibility_date,
      dates.conditional_release_date
    ].compact.map { |date| date - 12.weeks }.min
  end

  def self.nps_handover_date(subject, dates)
    if subject.early_allocation?
      return [early_allocation_handover_date(dates), 'NPS Early']
    end

    if subject.indeterminate_sentence?
      [indeterminate_responsibility_date(dates), 'NPS Inderminate']
    elsif dates.parole_eligibility_date.present?
      [dates.parole_eligibility_date - 8.months, 'NPS Determinate Parole Case']
    elsif subject.mappa_level.blank?
      [nil, 'NPS - MAPPA missing from nDelius']
    elsif subject.mappa_level.in? [1, 0]
      [mappa1_responsibility_date(dates), 'NPS Determinate Mappa 1/N']
    else
      [mappa_23_responsibility_date(dates), 'NPS Determinate Mappa 2/3']
    end
  end

  def self.indeterminate_responsibility_date(dates)
    [
      dates.parole_eligibility_date,
      dates.tariff_date
    ].compact.map { |date| date - 8.months }.min
  end

  # There are a couple of places where we need .5 of a month - which
  # we have assumed 15.days is a reasonable compromise implementation
  def self.mappa_23_responsibility_date(dates)
    [
      dates.conditional_release_date,
      dates.automatic_release_date
    ].compact.map { |date| date - (7.months + 15.days) }.min
  end

  def self.mappa1_responsibility_date(dates)
    crd_ard = [
      dates.conditional_release_date,
      dates.automatic_release_date
    ].compact.map { |date| date - (4.months + 15.days) }.min

    [
      crd_ard,
      dates.home_detention_curfew_eligibility_date
    ].compact.min
  end

  def self.early_allocation_handover_date(dates)
    [
      dates.conditional_release_date,
      dates.automatic_release_date
    ].compact.map { |date| date - 15.months }.min
  end
end
