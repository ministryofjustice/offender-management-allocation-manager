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

  def self.calculate_pom_responsibility(offender)
    if offender.immigration_case? || open_prison_nps_offender?(offender)
      SUPPORTING
    elsif offender.earliest_release_date.nil?
      RESPONSIBLE
    elsif offender.indeterminate_sentence? && offender.earliest_release_date < Time.zone.today
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
      if release_date_gt_10_mths?(offender) && (HandoverDateService.handover(offender).handover_date > Time.zone.today)
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

  private

    def release_date_gt_10_mths?(offender)
      offender.earliest_release_date >
        offender.sentence_start_date + 10.months
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
      if release_date_gt_15_mths_at_policy_date?(offender)
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

    def release_date_gt_15_mths_at_policy_date?(offender)
      offender.earliest_release_date >
        WELSH_POLICY_START_DATE + 15.months
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
      if hub_or_private?(offender)
        threshold = 20.months
      else
        threshold = 17.months
      end
      if release_date_gt_mths_at_policy_date?(offender, threshold)
        RESPONSIBLE
      else
        SUPPORTING
      end
    end

    def hub_or_private?(offender)
      PrisonService.english_hub_prison?(offender.prison_id) ||
        PrisonService.english_private_prison?(offender.prison_id)
    end

    def release_date_gt_mths_at_policy_date?(offender, threshold)
      offender.earliest_release_date >
        ORIGINAL_ENGLISH_POLICY_START_DATE + threshold
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
      earliest_release_date = [offender.earliest_release_date, offender.home_detention_curfew_eligibility_date].compact.min

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

end
