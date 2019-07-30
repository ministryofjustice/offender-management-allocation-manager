# frozen_string_literal: true

class ResponsibilityService
  RESPONSIBLE = 'Responsible'
  SUPPORTING = 'Supporting'
  COWORKING = 'Co-Working'
  NPS = 'NPS'

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def calculate_pom_responsibility(offender)
    return RESPONSIBLE if offender.sentence.earliest_release_date.nil?
    return SUPPORTING unless omicable?(offender)

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

  def omicable?(offender)
    offender.omicable == true
  end

  def nps_case?(offender)
    @nps_case ||= offender.case_allocation == NPS
  end

  def release_date_gt_10_mths?(offender)
    @release_date_gt_10_mths = offender.sentence.earliest_release_date >
      DateTime.now.utc.to_date + 10.months
  end

  def release_date_gt_15_mths?(offender)
    @release_date_gt_15_mths ||= offender.sentence.earliest_release_date >
      DateTime.new(2019, 2, 4).utc.to_date + 15.months
  end

  def release_date_gt_12_weeks?(offender)
    @release_date_gt_12_weeks ||= offender.sentence.earliest_release_date >
      DateTime.now.utc.to_date + 12.weeks
  end

  def new_case?(offender)
    return true unless offender.sentenced?

    offender.sentence.sentence_start_date > DateTime.new(2019, 2, 4).utc
  end
end
