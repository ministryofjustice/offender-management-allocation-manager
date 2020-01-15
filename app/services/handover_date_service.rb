# frozen_string_literal: true

class HandoverDateService
  HandoverData = Struct.new :start_date, :handover_date, :reason

  def self.handover(offender)
    if offender.recalled?
      HandoverData.new nil, nil, 'Recall case - no handover date calculation'
    elsif offender.nps_case? && offender.indeterminate_sentence? && offender.tariff_date.nil? # earliest_release_date

      # if offender.earliest_release_date.nil?
      HandoverData.new nil, nil, 'No earliest release date'

    elsif offender.nps_case?
      date, reason = nps_handover_date(offender)
      HandoverData.new nps_start_date(offender), date, reason
    else
      HandoverData.new nil, crc_handover_date(offender), 'CRC Case'
    end
  end

private

  def self.nps_start_date(offender)
    if offender.early_allocation?
      early_allocation_handover_date(offender)
    elsif offender.indeterminate_sentence?
      offender.tariff_date - 8.months # earliest_release_date
    elsif offender.parole_eligibility_date.present?
      offender.parole_eligibility_date - 8.months
    else
      [
        offender.conditional_release_date,
        offender.automatic_release_date
      ].compact.min - (7.months + 15.days)
    end
  end

  def self.crc_handover_date(offender)
    [
        offender.home_detention_curfew_eligibility_date,
        offender.conditional_release_date
    ].compact.map { |date| date - 12.weeks }.min
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

  def self.indeterminate_responsibility_date(offender)
    [
        offender.parole_eligibility_date,
        offender.tariff_date
    ].compact.map { |date| date - 8.months }.min
  end

  # There are a couple of places where we need .5 of a month - which
  # we have assumed 15.days is a reasonable compromise implementation
  def self.mappa_23_responsibility_date(offender)
    [
        offender.conditional_release_date,
        offender.automatic_release_date
    ].compact.map { |date| date - (7.months + 15.days) }.min
  end

  def self.mappa1_responsibility_date(offender)
    crd_ard = [
        offender.conditional_release_date,
        offender.automatic_release_date
    ].compact.map { |date| date - (4.months + 15.days) }.min

    [
        crd_ard,
        offender.home_detention_curfew_eligibility_date
    ].compact.min
  end

  def self.early_allocation_handover_date(offender)
    [
        offender.conditional_release_date,
        offender.automatic_release_date
    ].compact.map { |date| date - 15.months }.min
  end
end
