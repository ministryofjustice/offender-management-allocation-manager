# frozen_string_literal: true

class HandoverDateService
  Responsibility = Struct.new(:responsible?, :supporting?)

  RESPONSIBLE = Responsibility.new true, false
  SUPPORTING = Responsibility.new false, true
  NOT_INVOLVED = Responsibility.new false, false

  # OMIC open prison rules initially piloted in HMP Prescoed for Welsh offenders entering from 19/10/2020
  PRESCOED_POLICY_START_DATE = '19/10/2020'.to_date

  # OMIC open prison rules apply to the rest of the open estate from 31/03/2021
  OPEN_PRISON_POLICY_START_DATE = '31/03/2021'.to_date

  # OMIC apply to the womens' estate from 30/04/2021
  WOMENS_POLICY_START_DATE = Date.parse(ENV.fetch('WOMENS_POLICY_START_DATE', '30/04/2021'))

  class HandoverData
    REASONS = {
      com_responsibility: 'COM Responsibility',
      recall_case: 'Recall case',
      immigration_case: 'Immigration Case',
      release_date_unknown: 'Release Date Unknown',
      open_prison_pre_omic_rules: 'Open Prison pre-OMIC Rules',
      unsentenced: 'Unsentenced',
      crc_case: 'CRC Case',
      nps_early_allocation: 'NPS Early Allocation',
      nps_indeterminate: 'NPS Inderminate',
      nps_determinate_parole_case: 'NPS Determinate Parole Case',
      nps_mappa_unknown: 'NPS - MAPPA level unknown',
      nps_determinate_mappa_1_n: 'NPS Determinate Mappa 1/N',
      nps_determinate_mappa_2_3: 'NPS Determinate Mappa 2/3',
      less_than_10_months_left_to_serve: 'Less than 10 months left to serve'
    }.freeze

    attr_reader :start_date, :handover_date

    def initialize custody:, community:, start_date:, handover_date:, reason:
      @custody = custody
      @community = community
      @start_date = start_date
      @handover_date = handover_date
      @reason = reason
    end

    def custody_responsible?
      @custody.responsible?
    end

    def custody_supporting?
      @custody.supporting?
    end

    def community_responsible?
      @community.responsible?
    end

    def community_supporting?
      @community.supporting?
    end

    def reason
      REASONS.fetch(@reason, "Unknown handover reason #{@reason}")
    end
  end

  # if COM responsible, then handover dates all empty
  NO_HANDOVER_DATE = HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                                      start_date: nil, handover_date: nil,
                                      reason: :com_responsibility

  def self.handover(raw_offender)
    offender = OffenderWrapper.new(raw_offender)

    if offender.recalled?
      HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                       start_date: nil, handover_date: nil,
                       reason: :recall_case

    elsif offender.immigration_case?
      HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                       start_date: nil, handover_date: nil,
                       reason: :immigration_case

    elsif offender.release_date.blank?
      HandoverData.new custody: RESPONSIBLE, community: NOT_INVOLVED,
                       start_date: nil, handover_date: nil,
                       reason: :release_date_unknown

    # Indeterminate offenders should only ever be NPS
    # There is no such thing as a CRC indeterminate offender
    # So in theory, it should be safe to assume that indeterminate offenders are NPS
    # But in practice, there are some indeterminate offenders who are incorrectly recorded as CRC cases
    # (likely due to HOMDs choosing CRC just to 'get past' the missing information screen when the offender isn't in nDelius)
    # By using || here, we effectively ignore their CRC designation and treat them an NPS offender
    elsif offender.nps_case? || offender.indeterminate_sentence?
      if offender.in_open_conditions? && !offender.open_prison_rules_apply?
        # Offender is in open prison under pre-OMIC rules – COM is always responsible
        HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                         start_date: nil, handover_date: nil,
                         reason: :open_prison_pre_omic_rules
      else
        handover_date, reason = nps_handover_date(offender)
        start_date = nps_start_date(offender)
        handover_date = start_date if start_date.present? && start_date > handover_date

        if offender.policy_case?
          # we can't calculate responsibility if sentence_start_date is empty, so return NOT_INVOLVED rather than a page error
          if offender.sentence_start_date.blank?
            HandoverData.new custody: NOT_INVOLVED, community: NOT_INVOLVED,
                             start_date: nil, handover_date: nil,
                             reason: :unsentenced
          elsif offender.expected_time_in_custody_gt_10_months?
            if handover_date > Time.zone.today
              HandoverData.new custody: RESPONSIBLE, community: com_responsibility(start_date, handover_date),
                               start_date: start_date, handover_date: handover_date,
                               reason: reason
            else
              HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                               start_date: start_date, handover_date: handover_date,
                               reason: reason
            end
          else
            HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                             start_date: nil, handover_date: nil,
                             reason: :less_than_10_months_left_to_serve
          end
        # pre-policy can only be responsible or supporting
        elsif offender.nps_prepolicy_responsibility(handover_date) == RESPONSIBLE
          HandoverData.new custody: RESPONSIBLE, community: com_responsibility(start_date, handover_date),
                           start_date: start_date, handover_date: handover_date,
                           reason: reason
        else
          HandoverData.new custody: SUPPORTING, community: RESPONSIBLE,
                           start_date: start_date, handover_date: handover_date,
                           reason: reason
        end
      end
    else
      # CRC case
      crc_date = offender.release_date - 12.weeks
      if crc_date.future?
        pom = RESPONSIBLE
        com = NOT_INVOLVED
      else
        pom = SUPPORTING
        com = RESPONSIBLE
      end
      HandoverData.new custody: pom, community: com,
                         start_date: crc_date, handover_date: crc_date,
                         reason: :crc_case
    end
  end

private

  def self.com_responsibility(start_date, handover_date)
    if start_date.present? && handover_date.present? && Time.zone.today.between?(start_date, handover_date)
      SUPPORTING
    else
      NOT_INVOLVED
    end
  end

  def self.nps_start_date(offender)
    if offender.open_prison_rules_apply? && offender.indeterminate_sentence?
      offender.prison_arrival_date
    elsif offender.early_allocation?
      early_allocation_handover_date(offender)
    elsif offender.indeterminate_sentence?
      indeterminate_responsibility_date(offender)
    else
      determinate_sentence_handover_start_date(offender)
    end
  end

  def self.early_allocation_handover_date(offender)
    offender.release_date - 15.months
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

  def self.nps_handover_date(offender)
    if offender.early_allocation?
      [early_allocation_handover_date(offender), :nps_early_allocation]
    elsif offender.indeterminate_sentence?
      [indeterminate_responsibility_date(offender), :nps_indeterminate]
    elsif offender.parole_eligibility_date.present?
      [offender.parole_eligibility_date - 8.months, :nps_determinate_parole_case]
    elsif offender.mappa_level.blank?
      [mappa1_responsibility_date(offender), :nps_mappa_unknown]
    elsif offender.mappa_level.in? [1, 0]
      [mappa1_responsibility_date(offender), :nps_determinate_mappa_1_n]
    else
      [mappa_23_responsibility_date(offender), :nps_determinate_mappa_2_3]
    end
  end

  def self.indeterminate_responsibility_date(offender)
    offender.release_date - 8.months
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

  WELSH_POLICY_START_DATE = DateTime.new(2019, 2, 4).utc.to_date.freeze
  WELSH_CUTOFF_DATE = '4 May 2020'.to_date.freeze

  ENGLISH_POLICY_START_DATE = DateTime.new(2019, 10, 1).utc.to_date
  ENGLISH_PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
  ENGLISH_PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

  WOMENS_CUTOFF_DATE = '30/9/2022'.to_date

  class OffenderWrapper
    delegate :recalled?, :immigration_case?, :nps_case?, :indeterminate_sentence?,
             :early_allocation?, :mappa_level, :prison_arrival_date, :sentence_start_date,
             :parole_eligibility_date, :conditional_release_date, :automatic_release_date,
             :home_detention_curfew_eligibility_date, :home_detention_curfew_actual_date,
             to: :@offender

    def initialize(offender)
      @offender = offender
    end

    def policy_case?
      if in_womens_prison?
        new_case? WOMENS_POLICY_START_DATE
      elsif welsh_offender?
        new_case? WELSH_POLICY_START_DATE
      else
        new_case? ENGLISH_POLICY_START_DATE
      end
    end

    def nps_prepolicy_responsibility handover_date
      if in_womens_prison?
        nps_prepolicy_rules handover_date: handover_date, cutoff_date: WOMENS_CUTOFF_DATE
      elsif welsh_offender?
        nps_prepolicy_rules handover_date: handover_date, cutoff_date: WELSH_CUTOFF_DATE
      elsif hub_or_private?
        nps_prepolicy_rules handover_date: handover_date, cutoff_date: ENGLISH_PRIVATE_CUTOFF
      else
        nps_prepolicy_rules handover_date: handover_date, cutoff_date: ENGLISH_PUBLIC_CUTOFF
      end
    end

    # We can not calculate the handover date for NPS Indeterminate
    # with parole cases where the TED is in the past as we need
    # the parole board decision which currently is not available to us.
    def release_date
      if @offender.indeterminate_sentence?
        if @offender.tariff_date.present? && @offender.tariff_date.future?
          @offender.tariff_date
        else
          [
            @offender.parole_review_date,
            @offender.parole_eligibility_date
          ].compact.reject(&:past?).min
        end
      elsif @offender.nps_case?
        possible_dates = [@offender.conditional_release_date, @offender.automatic_release_date]
        @offender.parole_eligibility_date || possible_dates.compact.min
      else
        # CRC can look at HDC date, NPS is not supposed to
        @offender.home_detention_curfew_actual_date.presence ||
          [@offender.automatic_release_date,
           @offender.conditional_release_date,
           @offender.home_detention_curfew_eligibility_date].compact.min
      end
    end

    def open_prison_rules_apply?
      (
        # Offender falls into the HMP Prescoed open prison pilot
        @offender.prison_id == PrisonService::PRESCOED_CODE &&
          @offender.prison_arrival_date >= PRESCOED_POLICY_START_DATE &&
          welsh_offender?
      ) ||
      (
        # Open prison rules apply because offender arrived after the open prison policy general start date
        in_male_open_prison? && @offender.prison_arrival_date >= OPEN_PRISON_POLICY_START_DATE
      ) ||
      (
        in_womens_prison? && @offender.category_code == 'T'
      )
    end

    def in_womens_prison?
      PrisonService.womens_prison?(@offender.prison_id)
    end

    def hub_or_private?
      PrisonService.english_hub_prison?(@offender.prison_id) ||
          PrisonService.english_private_prison?(@offender.prison_id)
    end

    def welsh_offender?
      @offender.welsh_offender == true
    end

    def in_male_open_prison?
      PrisonService.open_prison?(@offender.prison_id)
    end

    def in_open_conditions?
      PrisonService.open_prison?(@offender.prison_id) || (PrisonService.womens_prison?(@offender.prison_id) && @offender.category_code == 'T')
    end

    def nps_prepolicy_rules handover_date:, cutoff_date:
      if release_date >= cutoff_date && handover_date > Time.zone.today
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

    def expected_time_in_custody_gt_10_months?
      release_date > @offender.sentence_start_date + 10.months
    end

  private

    def new_case? policy_start_date
      if @offender.sentenced?
        @offender.sentence_start_date >= policy_start_date
      else
        true
      end
    end
  end
end
