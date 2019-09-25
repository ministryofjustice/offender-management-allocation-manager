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

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.calculate_pom_responsibility(offender)
    return RESPONSIBLE if offender.sentence.earliest_release_date.nil?
    return SUPPORTING unless welsh_offender?(offender)

    return RESPONSIBLE if nps_case?(offender) &&
      new_case?(offender) &&
      release_date_gt_10_mths?(offender)

    return RESPONSIBLE if nps_case?(offender) &&
      !new_case?(offender) &&
      release_date_gt_15_mths?(offender)

    return RESPONSIBLE if !nps_case?(offender) &&
      release_date_gt_12_weeks?(offender)

    return SUPPORTING if !nps_case?(offender) &&
      !release_date_gt_12_weeks?(offender)

    return SUPPORTING if nps_case?(offender) &&
      new_case?(offender) &&
      !release_date_gt_10_mths?(offender)

    return SUPPORTING if nps_case?(offender) &&
      !new_case?(offender) &&
      !release_date_gt_15_mths?(offender)
  end

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity

private

  def self.welsh_offender?(offender)
    offender.welsh_offender == true
  end

  def self.nps_case?(offender)
    offender.case_allocation == NPS
  end

  def self.release_date_gt_10_mths?(offender)
    offender.sentence.earliest_release_date >
      DateTime.now.utc.to_date + 10.months
  end

  def self.release_date_gt_15_mths?(offender)
    offender.sentence.earliest_release_date >
      DateTime.new(2019, 2, 4).utc.to_date + 15.months
  end

  def self.release_date_gt_12_weeks?(offender)
    offender.sentence.earliest_release_date >
      DateTime.now.utc.to_date + 12.weeks
  end

  def self.new_case?(offender)
    return true unless offender.sentenced?

    offender.sentence.sentence_start_date > DateTime.new(2019, 2, 4).utc
  end
end
