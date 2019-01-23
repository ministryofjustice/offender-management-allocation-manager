class ResponsibilityService
  def self.calculate_responsibility(offender)
    case offender.case_allocation
    when 'NPS'
      nps_calculation(offender)
    when 'CRC'
      'Probation'
    else
      'Unknown'
    end
  end

  def self.nps_calculation(offender)
    return 'No release date' if offender.release_date.nil?

    more_than_10_months = offender.release_date > DateTime.now.utc.to_date + 10.months
    more_than_10_months ? 'Prison' : 'Probation'
  end
end
