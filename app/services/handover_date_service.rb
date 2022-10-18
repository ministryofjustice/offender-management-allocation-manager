# frozen_string_literal: true

# This class calculates the handover dates for offenders and is the authority for these. The dates calculated here are
# pushed to nDelius, for example.
#
# This class has 1 public class method - self.handover(). this returns a CalculatedHandoverDate model. The quirk,
# however, is that the models returned are new, in-memory ones. Each Offender has a saved one already attached to it
# (offender.calculated_handover_date) yet I cannot find any instance where it is used. Instead, we always calculate
# the handover date afresh by calling HandoverDateService::handover.
class HandoverDateService
  # OMIC open prison rules initially piloted in HMP Prescoed for Welsh offenders entering from 19/10/2020
  PRESCOED_POLICY_START_DATE = '19/10/2020'.to_date

  # OMIC open prison rules apply to the rest of the open estate from 31/03/2021
  OPEN_PRISON_POLICY_START_DATE = '31/03/2021'.to_date

  # OMIC apply to the womens' estate from 30/04/2021
  WOMENS_POLICY_START_DATE = Date.parse(ENV.fetch('WOMENS_POLICY_START_DATE', '30/04/2021'))

  # if COM responsible, then handover dates all empty
  NO_HANDOVER_DATE = CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                                start_date: nil, handover_date: nil,
                                                reason: :com_responsibility

  def self.handover(raw_offender)
    unless raw_offender.inside_omic_policy?
      raise "Offender #{raw_offender.offender_no} falls outside of OMIC policy - cannot calculate handover dates"
    end

    offender = OffenderWrapper.new(raw_offender)

    if offender.recalled?
      CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                 start_date: nil, handover_date: nil,
                                 reason: :recall_case

    elsif offender.immigration_case?
      CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                 start_date: nil, handover_date: nil,
                                 reason: :immigration_case

    elsif offender.release_date.blank?
      CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
                                 start_date: nil, handover_date: nil,
                                 reason: :release_date_unknown

    elsif offender.crc_case?
      # CRC cases don't have a 'handover window' – the 'start date' and 'handover date' are always the same
      handover_date = offender.release_date - 12.weeks
      CalculatedHandoverDate.new responsibility: responsibility(handover_date, handover_date),
                                 start_date: handover_date, handover_date: handover_date,
                                 reason: :crc_case

    elsif !offender.expected_time_in_custody_gt_10_months?
      # TODO: This should be part of the policy case check below

      # COM is always responsible if the expected time in custody is less than 10 months
      CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                 start_date: nil, handover_date: nil,
                                 reason: :less_than_10_months_left_to_serve

    elsif offender.policy_case?
      # Offender is NPS Determinate or Indeterminate
      handover_date, reason = nps_handover_date(offender)
      start_date = nps_start_date(offender)
      handover_date = start_date if start_date.present? && start_date > handover_date

      CalculatedHandoverDate.new responsibility: responsibility(start_date, handover_date),
                                 start_date: start_date, handover_date: handover_date,
                                 reason: reason

    else
      # This is a pre-OMIC policy case
      # e.g. they were sentenced before the OMIC policy start date and will be released before the cutoff date,
      #      or they entered an Open prison before OMIC rules applied there
      # COM is always responsible and there are no handover dates
      CalculatedHandoverDate.new responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                 start_date: nil, handover_date: nil,
                                 reason: :pre_omic_rules
    end
  end

private

  def self.responsibility(start_date, handover_date)
    if start_date&.future? && handover_date&.future?
      # POM responsible, no COM needed
      CalculatedHandoverDate::CUSTODY_ONLY
    elsif handover_date&.future?
      # POM responsible, COM supporting
      CalculatedHandoverDate::CUSTODY_WITH_COM
    else
      # POM supporting, COM responsible
      CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
    end
  end

  def self.nps_start_date(offender)
    if offender.open_prison_rules_apply? && offender.indeterminate_sentence?
      if offender.in_womens_prison?
        # Women's estate: the day the offender's category changed to "open"
        offender.category_active_since
      else
        # Men's estate: the day the offender arrived in the open prison
        offender.prison_arrival_date
      end
    else
      d = nps_handover_date(offender)
      d[0] if d
    end
  end

  def self.early_allocation_handover_date(offender)
    offender.release_date - 15.months
  end

  def self.nps_handover_date(offender)
    if offender.early_allocation?
      [early_allocation_handover_date(offender), :nps_early_allocation]
    elsif offender.indeterminate_sentence?
      reason = offender.in_open_conditions? ? :nps_indeterminate_open : :nps_indeterminate
      [indeterminate_responsibility_date(offender), reason]
    else
      nps_determinate_responsibility_date(offender)
    end
  end

  def self.indeterminate_responsibility_date(offender)
    offender.release_date - 8.months
  end

  def self.nps_determinate_responsibility_date(offender)
    if offender.parole_eligibility_date.present?
      [offender.parole_eligibility_date - 8.months, :nps_determinate_parole_case]
    elsif offender.conditional_release_date.present? || offender.automatic_release_date.present?
      if USE_HANDOVER_RULES_COMPONENT
        dates = Handover::HandoverDateRules.calculate_handover_dates(
          nomis_offender_id: offender.offender_no,
          sentence_start_date: offender.sentence_start_date,
          conditional_release_date: offender.conditional_release_date,
          automatic_release_date: offender.automatic_release_date)
        [dates.handover_date, dates.reason]
      else
        earliest_date = [
          offender.conditional_release_date,
          offender.automatic_release_date
        ].compact.min

        [earliest_date - (7.months + 15.days), :nps_determinate]
      end
    end
  end

  WELSH_POLICY_START_DATE = Time.zone.local(2019, 2, 4).utc.to_date.freeze
  WELSH_CUTOFF_DATE = '4 May 2020'.to_date.freeze

  ENGLISH_POLICY_START_DATE = Time.zone.local(2019, 10, 1).utc.to_date
  ENGLISH_PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
  ENGLISH_PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

  WOMENS_CUTOFF_DATE = '30/9/2022'.to_date

  class OffenderWrapper
    delegate :recalled?, :immigration_case?, :indeterminate_sentence?,
             :early_allocation?, :mappa_level, :prison_arrival_date, :category_active_since,
             :parole_eligibility_date, :conditional_release_date, :automatic_release_date,
             :home_detention_curfew_eligibility_date, :home_detention_curfew_actual_date,
             :sentence_start_date, :offender_no,
             to: :@offender

    def initialize(offender)
      @offender = offender
    end

    # CRC cases can only have determinate sentences
    # There is no such thing as a CRC indeterminate offender
    # So in theory, it should be safe to assume that indeterminate offenders are NPS
    # But in practice, there are some indeterminate offenders who are incorrectly recorded as CRC cases
    # (likely due to HOMDs choosing CRC just to 'get past' the missing information screen when the offender isn't in nDelius)
    def crc_case?
      !@offender.nps_case? && !@offender.indeterminate_sentence?
    end

    # Work out if OMIC policy rules apply to this case
    def policy_case?
      sentenced_after_policy_started = @offender.sentence_start_date >= policy_start_date
      release_after_cutoff = release_date >= policy_cutoff_date

      # Offenders must have been sentenced on/after the OMIC policy start date,
      # or have a release date which is on/after the 'cutoff' date.
      within_policy_dates = (sentenced_after_policy_started || release_after_cutoff)

      if in_open_conditions?
        # There are additional rules to decide if OMIC open prison rules apply
        within_policy_dates && open_prison_rules_apply?
      else
        within_policy_dates
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
        # Open policy launched before Women's prisons – so no need to check for a 'women's open policy start date'
        in_womens_prison? && @offender.category_code == 'T'
      )
    end

    def in_womens_prison?
      # TODO: We should be able to use @offender.prison.womens? (much nicer!), but first we'll need to replace use of
      #       OpenStruct objects in the tests with proper MpcOffender objects
      PrisonService.womens_prison?(@offender.prison_id)
    end

    def in_open_conditions?
      in_male_open_prison? || (in_womens_prison? && @offender.category_code == 'T')
    end

    def expected_time_in_custody_gt_10_months?
      release_date > @offender.sentence_start_date + 10.months
    end

  private

    def in_male_open_prison?
      # TODO: We should be able to use @offender.prison.mens_open? (much nicer!), but first we'll need to replace use of
      #       OpenStruct objects in the tests with proper MpcOffender objects
      PrisonService.open_prison?(@offender.prison_id)
    end

    def hub_or_private?
      PrisonService.english_hub_prison?(@offender.prison_id) ||
        PrisonService.english_private_prison?(@offender.prison_id)
    end

    def welsh_offender?
      @offender.welsh_offender == true
    end

    def policy_start_date
      if in_womens_prison?
        WOMENS_POLICY_START_DATE
      elsif welsh_offender?
        WELSH_POLICY_START_DATE
      else
        ENGLISH_POLICY_START_DATE
      end
    end

    def policy_cutoff_date
      if in_womens_prison?
        WOMENS_CUTOFF_DATE
      elsif welsh_offender?
        WELSH_CUTOFF_DATE
      elsif hub_or_private?
        ENGLISH_PRIVATE_CUTOFF
      else
        ENGLISH_PUBLIC_CUTOFF
      end
    end
  end
end
