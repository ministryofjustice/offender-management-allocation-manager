# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/CyclomaticComplexity
class ResponsibilityService
  NPS = 'NPS'
  CRC = 'CRC'
  PRISON = 'Prison'
  PROBATION = 'Probation'
  UNKNOWN = 'Unknown'
  RESPONSIBLE = 'Responsible'
  SUPPORTING = 'Supporting'

  def calculate_case_owner(offender)
    case offender.case_allocation
    when NPS
      nps_calculation(offender)
    when CRC
      PRISON
    else
      UNKNOWN
    end
  end

  def calculate_pom_responsibility(offender)
    return UNKNOWN if offender.release_date.nil?
    return SUPPORTING unless welsh?(offender)

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

private

  def welsh?(offender)
    offender.welsh_address == true
  end

  def nps_case?(offender)
    @nps_case ||= offender.case_allocation == NPS
  end

  def release_date_gt_10_mths?(offender)
    @release_date_gt_10_mths = offender.release_date > DateTime.now.utc.to_date + 10.months
  end

  def release_date_gt_15_mths?(offender)
    @release_date_gt_15_mths ||= offender.release_date > DateTime.new(2019, 2, 4).utc.to_date + 15.months
  end

  def release_date_gt_12_weeks?(offender)
    @release_date_gt_12_weeks ||= offender.release_date > DateTime.now.utc.to_date + 12.weeks
  end

  def new_case?(offender)
    @new_case ||= offender.sentence_date > DateTime.new(2019, 2, 4).utc
  end

  def nps_calculation(offender)
    return 'No release date' if offender.release_date.nil?

    offender.tier == 'A' || offender.tier == 'B' ? PROBATION : PRISON
  end

  def assign_responsible?(offender)
    # TODO: When we do this check, we should also check what the responsibility
    # was yesterday, so that we can determine if it has changed.  This will allow
    # us to persist the responsibility at the time of allocation, and when the
    # responsibility changes do:
    #   * Notifications
    #   * Deactive and recreate allocation (with new responsibility)
    offender.welsh_address == true &&
      offender.release_date > DateTime.now.utc.to_date + 10.months
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/LineLength
