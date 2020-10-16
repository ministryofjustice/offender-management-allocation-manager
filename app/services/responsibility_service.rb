# frozen_string_literal: true

class ResponsibilityService
  Responsibility = Struct.new(:description, :custody?, :case_owner) do
    def to_s
      description
    end
  end

  RESPONSIBLE = Responsibility.new 'Responsible', true, 'Custody'
  SUPPORTING = Responsibility.new 'Supporting', false, 'Community'
  UNKNOWN = Responsibility.new 'Unknown', false, 'Unknown'
  COWORKING = 'Co-Working'
  # Actual date Mon 19th Oct 2020
  PRESCOED_CUTOFF_DATE = Date.new(2020, 10, 19).freeze

  # We currently don't have access to the date of the parole board decision, which means that we cannot correctly
  # calculate responsibility for NPS indeterminate cases with parole eligibility where the TED is in the past.
  # A decision has been made to display a notice so staff can check whether they need to override their case or not;
  # this is until we get access to this data.
  def self.calculate_pom_responsibility(offender)
    if offender.immigration_case?
      SUPPORTING
    elsif open_prison_nps_offender?(offender) && !recent_prescoed_nps_case?(offender)
      SUPPORTING
    elsif offender.recalled?
      SUPPORTING
    elsif determinate_with_no_release_dates?(offender)
      RESPONSIBLE
    elsif offender.indeterminate_sentence? && (offender.tariff_date.nil? ||
       offender.tariff_date < Time.zone.today)

      RESPONSIBLE
    else
      standard_rules(offender)
    end
  end

  def self.recent_prescoed_nps_case?(offender)
    offender.prison_id == PrisonService::PRESCOED_CODE &&
        offender.prison_arrival_date >= PRESCOED_CUTOFF_DATE &&
        offender.nps_case? && welsh_offender?(offender)
  end

private

  def self.standard_rules(offender)
    if offender.nps_case? || offender.indeterminate_sentence?
      nps_rules(offender)
    else
      crc_rules(offender)
    end
  end

  class NpsResponsibilityRules
    def initialize(policy_start_date)
      @policy_start_date = policy_start_date
    end

    def new_case?(offender)
      if offender.sentenced?
        offender.sentence_start_date > @policy_start_date
      else
        true
      end
    end

    def policy_rules(offender)
      release_date = offender.parole_eligibility_date

      if offender.indeterminate_sentence?
        release_date ||= offender.tariff_date
      else
        possible_dates = [offender.conditional_release_date, offender.automatic_release_date]
        release_date ||= possible_dates.compact.min
      end

      return UNKNOWN if release_date.blank?

      expected_time_in_custody_gt_10_months = release_date > offender.sentence_start_date + 10.months
      handover_date_in_future = HandoverDateService.handover(offender).handover_date > Time.zone.today

      if expected_time_in_custody_gt_10_months && handover_date_in_future
        RESPONSIBLE
      else
        SUPPORTING
      end
    end
  end

  class WelshNpsResponsibiltyRules < NpsResponsibilityRules
    WELSH_POLICY_START_DATE = DateTime.new(2019, 2, 4).utc.to_date

    def initialize
      super WELSH_POLICY_START_DATE
    end

    def responsibility(offender)
      if new_case?(offender)
        policy_rules(offender)
      else
        welsh_prepolicy_rules(offender)
      end
    end

  private

    def welsh_prepolicy_rules(offender)
      cutoff = '4 May 2020'.to_date

      release_date = offender.parole_eligibility_date

      if offender.indeterminate_sentence?
        release_date ||= offender.tariff_date
      else
        possible_dates = [offender.conditional_release_date, offender.automatic_release_date]
        release_date ||= possible_dates.compact.min
      end

      return UNKNOWN if release_date.blank?

      handover_date_in_future = HandoverDateService.handover(offender).handover_date > Time.zone.today
      if handover_date_in_future && release_date >= cutoff
        RESPONSIBLE
      else
        SUPPORTING
      end
    end
  end

  class EnglishNpsResponsibilityRules < NpsResponsibilityRules
    ENGLISH_POLICY_START_DATE = DateTime.new(2019, 10, 1).utc.to_date
    ORIGINAL_ENGLISH_POLICY_START_DATE = DateTime.new(2019, 9, 16).utc.to_date

    def initialize
      super ENGLISH_POLICY_START_DATE
    end

    def responsibility(offender)
      if new_case?(offender)
        policy_rules(offender)
      else
        english_prepolicy_rules(offender)
      end
    end

  private

    PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
    PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

    def english_prepolicy_rules(offender)
      release_date = offender.parole_eligibility_date

      if offender.indeterminate_sentence?
        release_date ||= offender.tariff_date
      else
        possible_dates = [offender.conditional_release_date, offender.automatic_release_date]
        release_date ||= possible_dates.compact.min
      end

      return UNKNOWN if release_date.blank?

      cutoff = hub_or_private?(offender) ? PRIVATE_CUTOFF : PUBLIC_CUTOFF

      handover_date_in_future = HandoverDateService.handover(offender).handover_date > Time.zone.today

      if handover_date_in_future && release_date >= cutoff
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

    def hub_or_private?(offender)
      PrisonService.english_hub_prison?(offender.prison_id) ||
        PrisonService.english_private_prison?(offender.prison_id)
    end
  end

  def self.nps_rules(offender)
    if welsh_offender?(offender)
      WelshNpsResponsibiltyRules.new.responsibility(offender)
    else
      EnglishNpsResponsibilityRules.new.responsibility(offender)
    end
  end

  def self.open_prison_nps_offender?(offender)
    PrisonService.open_prison?(offender.prison_id) && offender.nps_case?
  end

  class CrcRules
    def self.responsibility(offender)
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
  end

  def self.crc_rules(offender)
    CrcRules.responsibility(offender)
  end

  def self.welsh_offender?(offender)
    offender.welsh_offender == true
  end

  def self.determinate_with_no_release_dates?(offender)
    offender.indeterminate_sentence? == false &&
        offender.automatic_release_date.nil? &&
        offender.conditional_release_date.nil? &&
        offender.parole_eligibility_date.nil? &&
        offender.home_detention_curfew_eligibility_date.nil?
  end
end
