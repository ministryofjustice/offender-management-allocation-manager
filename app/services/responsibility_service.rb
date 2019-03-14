class ResponsibilityService
  def self.calculate_case_owner(offender)
    case offender.case_allocation
    when 'NPS'
      nps_calculation(offender)
    when 'CRC'
      'Prison'
    else
      'Unknown'
    end
  end

  def self.calculate_pom_responsibility(offender)
    return 'Unknown' if offender.release_date.nil?
    return 'Responsible' if offender.welsh_address == true && release_date_gt_10_months(offender)
    'Supporting'
  end

  def self.nps_calculation(offender)
    return 'No release date' if offender.release_date.nil?

    offender.tier == 'A' || offender.tier == 'B' ? 'Probation' : 'Prison'
  end

  def self.release_date_gt_10_months(offender)
    offender.release_date > DateTime.now.utc.to_date + 10.months
  end
end
