# frozen_string_literal: true

class ResponsibilityService
  Responsibility = Struct.new(:description, :custody?) do
    def to_s
      description
    end
  end

  RESPONSIBLE = Responsibility.new 'Responsible', true
  SUPPORTING = Responsibility.new 'Supporting', false
  COWORKING = 'Co-Working'
  NPS = 'NPS'

  # We currently don't have access to the date of the parole board decision, which means that we cannot correctly
  # calculate responsibility for NPS indeterminate cases with parole eligibility where the TED is in the past.
  # A decision has been made to display a notice so staff can check whether they need to override their case or not;
  # this is until we get access to this data.
  def self.calculate_pom_responsibility(offender)
    if offender.immigration_case? || open_prison_nps_offender?(offender)
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

private

  def self.standard_rules(offender)
    if offender.recalled?
      SUPPORTING
    elsif nps_case?(offender)
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

      return nil if release_date.blank?

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

      possible_dates = [offender.conditional_release_date, offender.automatic_release_date]
      release_date = offender.parole_eligibility_date
      release_date ||= possible_dates.compact.min

      return nil if release_date.blank?

      release_date >= cutoff ? RESPONSIBLE : SUPPORTING
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

    def english_prepolicy_rules(offender)
      private_cutoff = '1 Jun 2021'.to_date
      public_cutoff = '15 Feb 2021'.to_date

      possible_dates = [offender.conditional_release_date, offender.automatic_release_date]
      release_date = offender.parole_eligibility_date
      release_date ||= possible_dates.compact.min

      return nil if release_date.blank?

      cutoff = hub_or_private?(offender) ? private_cutoff : public_cutoff

      release_date >= cutoff ? RESPONSIBLE : SUPPORTING
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
      if release_date_gt_12_weeks?(offender)
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

  private

    # CRC can look at HDC date, NPS is not supposed to
    def self.release_date_gt_12_weeks?(offender)
      earliest_release_date =
        offender.home_detention_curfew_actual_date.presence ||
            [offender.automatic_release_date,
             offender.conditional_release_date,
             offender.home_detention_curfew_eligibility_date].compact.min
      earliest_release_date > DateTime.now.utc.to_date + 12.weeks
    end
  end

  def self.crc_rules(offender)
    CrcRules.responsibility(offender)
  end

  def self.welsh_offender?(offender)
    offender.welsh_offender == true
  end

  def self.nps_case?(offender)
    offender.nps_case?
  end

  def self.determinate_with_no_release_dates?(offender)
    offender.indeterminate_sentence? == false &&
        offender.automatic_release_date.nil? &&
        offender.conditional_release_date.nil? &&
        offender.parole_eligibility_date.nil? &&
        offender.home_detention_curfew_eligibility_date.nil?
  end
end
