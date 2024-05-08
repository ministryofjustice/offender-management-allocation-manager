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

  def self.handover(mpc_offender)
    unless mpc_offender.inside_omic_policy?
      raise "Offender #{mpc_offender.offender_no} falls outside of OMIC policy - cannot calculate handover dates"
    end

    offender = OffenderWrapper.new(mpc_offender)

    if USE_PPUD_PAROLE_DATA && mpc_offender.sentenced_to_an_additional_isp?
      pom_only_is_responsible reason: :additional_isp

    elsif mpc_offender.recalled?
      com_is_responsible reason: :recall_case

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.tariff_date.try(:<=, 12.months.from_now)
      com_is_responsible reason: :within_12_months_of_tarrif_date

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.ppud_or_manually_entered_target_hearing_date.try(:<=, 12.months.from_now)
      com_is_responsible reason: :within_12_months_of_target_hearing_date

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.most_recent_parole_review&.no_hearing_outcome?
      com_is_responsible reason: :awaiting_parole_outcome

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.most_recent_completed_parole_review&.outcome_is_release?
      com_is_responsible reason: :parole_outcome_release

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.mappa_level.in?([nil, 1])
      pom_is_responsible reason: :parole_outcome_no_release_mappa_empty_or_1

    elsif USE_PPUD_PAROLE_DATA && mpc_offender.mappa_level.in?([2, 3])
      com_is_responsible reason: :parole_outcome_no_release_mappa_2_or_3

    elsif offender.immigration_case?
      com_is_responsible reason: :immigration_case

    elsif !offender.earliest_release
      pom_only_is_responsible reason: :release_date_unknown

    elsif !offender.policy_case?
      com_is_responsible reason: :pre_omic_rules

    else
      handover_date, reason = Handover::HandoverCalculation.calculate_handover_date(
        sentence_start_date: offender.sentence_start_date,
        earliest_release_date: offender.earliest_release.date,
        is_early_allocation: offender.early_allocation?,
        is_indeterminate: offender.indeterminate_sentence?,
        in_open_conditions: offender.in_open_conditions?,
        is_determinate_parole: offender.determinate_parole?,
      )
      start_date = Handover::HandoverCalculation.calculate_handover_start_date(
        handover_date:,
        category_active_since_date: offender.category_active_since,
        prison_arrival_date: offender.prison_arrival_date,
        is_indeterminate: offender.indeterminate_sentence?,
        open_prison_rules_apply: offender.open_prison_rules_apply?,
        in_womens_prison: offender.in_womens_prison?,
      )
      responsibility = Handover::HandoverCalculation.calculate_responsibility(
        handover_date: handover_date,
        handover_start_date: start_date,
      )
      CalculatedHandoverDate.new responsibility:, start_date:, handover_date:, reason:
    end
  end

private

  def self.com_is_responsible(extra_attributes = {})
    CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE, **extra_attributes)
  end

  def self.pom_only_is_responsible(extra_attributes = {})
    CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::CUSTODY_ONLY, **extra_attributes)
  end

  def self.pom_is_responsible(extra_attributes = {})
    CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::CUSTODY_WITH_COM, **extra_attributes)
  end

  WELSH_POLICY_START_DATE = Time.zone.local(2019, 2, 4).utc.to_date.freeze
  WELSH_CUTOFF_DATE = '4 May 2020'.to_date.freeze

  ENGLISH_POLICY_START_DATE = Time.zone.local(2019, 10, 1).utc.to_date
  ENGLISH_PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
  ENGLISH_PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

  WOMENS_CUTOFF_DATE = '30/9/2022'.to_date

  # TODO: Clean up all the shit here that's no longer used
  class OffenderWrapper
    delegate :recalled?, :immigration_case?, :indeterminate_sentence?,
             :early_allocation?, :mappa_level, :prison_arrival_date, :category_active_since,
             :parole_eligibility_date, :conditional_release_date, :automatic_release_date,
             :tariff_date, :target_hearing_date,
             :home_detention_curfew_eligibility_date, :home_detention_curfew_actual_date,
             :sentence_start_date, :offender_no,
             :determinate_parole?,
             to: :@offender

    def initialize(offender)
      @offender = offender
    end

    # Work out if OMIC policy rules apply to this case
    def policy_case?
      sentenced_after_policy_started = @offender.sentence_start_date >= policy_start_date
      release_after_cutoff = release_date >= policy_cutoff_date

      # Offenders must have been sentenced on/after the OMIC policy start date,
      # or have a release date which is on/after the 'cutoff' date.
      within_policy_dates = sentenced_after_policy_started || release_after_cutoff

      if in_open_conditions?
        # There are additional rules to decide if OMIC open prison rules apply
        within_policy_dates && open_prison_rules_apply?
      else
        within_policy_dates
      end
    end

    def earliest_release
      @earliest_release ||= @offender.earliest_release_for_handover
    end

    def release_date
      earliest_release&.date
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
