# frozen_string_literal: true

class HandoverDateService
  Responsibility = Struct.new(:description, :custody?, :case_owner) do
    def to_s
      description
    end
  end

  RESPONSIBLE = Responsibility.new 'Responsible', true, 'Custody'
  SUPPORTING = Responsibility.new 'Supporting', false, 'Community'
  UNKNOWN = Responsibility.new 'Unknown', false, 'Unknown'

  # Actual date Mon 19th Oct 2020
  PRESCOED_CUTOFF_DATE = Date.new(2020, 10, 19).freeze

  HandoverData = Struct.new :responsibility, :start_date, :handover_date, :reason

  # if COM responsible, then handover dates all empty
  NO_HANDOVER_DATE = HandoverData.new SUPPORTING, nil, nil, 'COM Responsibility'

  def self.calculate_pom_responsibility(offender)
    handover(offender).responsibility
  end

  def self.handover(raw_offender)
    offender = OffenderWrapper.new(raw_offender)

    if offender.recalled?
      HandoverData.new SUPPORTING, nil, nil, 'Recall case'
    elsif offender.immigration_case?
      HandoverData.new SUPPORTING, nil, nil, 'Immigration Case'
    elsif offender.nps_case? && offender.indeterminate_sentence? && (offender.tariff_date.nil? || offender.tariff_date < Time.zone.today)
      HandoverData.new RESPONSIBLE, nil, nil, 'No earliest release date'
    elsif offender.recent_prescoed_case? && offender.indeterminate_sentence? && offender.nps_case?
      handover_date = prescoed_handover_date(offender)
      HandoverData.new SUPPORTING, offender.prison_arrival_date, handover_date, 'Prescoed'
    elsif offender.nps_case? || offender.indeterminate_sentence?
      responsibility = responsibility_override(offender)
      if responsibility.nil?
        handover_date, reason = nps_handover_date(offender)
        start_date = nps_start_date(offender)
        handover_date = start_date if start_date > handover_date
        HandoverData.new nps_responsibility(offender, handover_date), start_date, handover_date, reason
      elsif responsibility == UNKNOWN
        HandoverData.new UNKNOWN, nil, nil, 'NPS Case - missing dates'
      else
        handover_date, reason = nps_handover_date(offender)
        HandoverData.new responsibility, nps_start_date(offender), handover_date, reason
      end
    else
      responsibility = crc_responsibility(offender)
      if responsibility == UNKNOWN
        HandoverData.new UNKNOWN, nil, nil, 'CRC Case - missing dates'
      else
        crc_date = crc_handover_date(offender)
        HandoverData.new responsibility, crc_date, crc_date, 'CRC Case'
      end
    end
  end

private

  # We currently don't have access to the date of the parole board decision, which means that we cannot correctly
  # calculate responsibility for NPS indeterminate cases with parole eligibility where the TED is in the past.
  # A decision has been made to display a notice so staff can check whether they need to override their case or not;
  # this is until we get access to this data.
  def self.responsibility_override(offender)
    if offender.open_prison_nps_offender? && !offender.recent_prescoed_case?
      SUPPORTING
    elsif offender.determinate_with_no_release_dates?
      RESPONSIBLE
    elsif offender.indeterminate_sentence? && (offender.tariff_date.nil? ||
        offender.tariff_date < Time.zone.today)
      RESPONSIBLE
    elsif offender.release_date.blank?
      UNKNOWN
    end
  end

  def self.prescoed_handover_date(offender)
    target_date = [offender.tariff_date, offender.parole_review_date, offender.parole_eligibility_date].compact.min
    target_date - 8.months
  end

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
      return [early_allocation_handover_date(offender), 'NPS Early Allocation']
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

  def self.nps_responsibility_rules(offender:, policy_start_date:, handover_date:, cutoff_date:)
    if offender.new_case? policy_start_date
      nps_policy_rules offender: offender, handover_date: handover_date
    else
      nps_prepolicy_rules offender: offender, handover_date: handover_date, cutoff_date: cutoff_date
    end
  end

  def self.nps_prepolicy_rules offender:, handover_date:, cutoff_date:
    if offender.release_date >= cutoff_date && handover_date > Time.zone.today
      RESPONSIBLE
    else
      SUPPORTING
    end
  end

  def self.nps_policy_rules offender:, handover_date:
    # we can't calculate responsibility if sentence_start_date is empty, so return UNKNOWN rather than a page error
    return UNKNOWN if offender.sentence_start_date.blank?

    if offender.expected_time_in_custody_gt_10_months? && handover_date > Time.zone.today
      RESPONSIBLE
    else
      SUPPORTING
    end
  end

  WELSH_POLICY_START_DATE = DateTime.new(2019, 2, 4).utc.to_date.freeze
  WELSH_CUTOFF_DATE = '4 May 2020'.to_date.freeze

  ENGLISH_POLICY_START_DATE = DateTime.new(2019, 10, 1).utc.to_date
  ENGLISH_PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
  ENGLISH_PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

  def self.nps_responsibility(offender, handover_date)
    if offender.welsh_offender?
      nps_responsibility_rules(offender: offender,
                               policy_start_date: WELSH_POLICY_START_DATE,
                               handover_date: handover_date,
                               cutoff_date: WELSH_CUTOFF_DATE)
    elsif offender.hub_or_private?
      nps_responsibility_rules(offender: offender,
                               policy_start_date: ENGLISH_POLICY_START_DATE,
                               handover_date: handover_date,
                               cutoff_date: ENGLISH_PRIVATE_CUTOFF)
    else
      nps_responsibility_rules(offender: offender,
                               policy_start_date: ENGLISH_POLICY_START_DATE,
                               handover_date: handover_date,
                               cutoff_date: ENGLISH_PUBLIC_CUTOFF)
    end
  end

  def self.crc_responsibility(offender)
    # CRC can look at HDC date, NPS is not supposed to
    earliest_release_date =
      offender.home_detention_curfew_actual_date.presence ||
          [offender.automatic_release_date,
           offender.conditional_release_date,
           offender.home_detention_curfew_eligibility_date].compact.min

    return UNKNOWN if earliest_release_date.nil?

    if earliest_release_date > DateTime.now.utc.to_date + 12.weeks
      RESPONSIBLE
    else
      SUPPORTING
    end
  end

  class OffenderWrapper
    delegate :recalled?, :immigration_case?, :nps_case?, :indeterminate_sentence?, :tariff_date,
             :early_allocation?, :mappa_level, :prison_arrival_date, :sentence_start_date,
             :parole_eligibility_date, :conditional_release_date, :automatic_release_date,
             :home_detention_curfew_eligibility_date, :home_detention_curfew_actual_date, :parole_review_date,
             to: :@offender

    def initialize(offender)
      @offender = offender
    end

    def determinate_with_no_release_dates?
      @offender.indeterminate_sentence? == false &&
        @offender.automatic_release_date.nil? &&
        @offender.conditional_release_date.nil? &&
        @offender.parole_eligibility_date.nil? &&
        @offender.home_detention_curfew_eligibility_date.nil?
    end

    def new_case? policy_start_date
      if @offender.sentenced?
        @offender.sentence_start_date > policy_start_date
      else
        true
      end
    end

    def expected_time_in_custody_gt_10_months?
      release_date > @offender.sentence_start_date + 10.months
    end

    def release_date
      if @offender.indeterminate_sentence?
        @offender.parole_eligibility_date || @offender.tariff_date
      else
        possible_dates = [@offender.conditional_release_date, @offender.automatic_release_date]
        @offender.parole_eligibility_date || possible_dates.compact.min
      end
    end

    def recent_prescoed_case?
      @offender.prison_id == PrisonService::PRESCOED_CODE &&
          @offender.prison_arrival_date >= PRESCOED_CUTOFF_DATE &&
          welsh_offender?
    end

    def hub_or_private?
      PrisonService.english_hub_prison?(@offender.prison_id) ||
          PrisonService.english_private_prison?(@offender.prison_id)
    end

    def welsh_offender?
      @offender.welsh_offender == true
    end

    def open_prison_nps_offender?
      PrisonService.open_prison?(@offender.prison_id) && @offender.nps_case?
    end
  end
end
