class ResponsibilityService
  def self.calculate_responsibility(offender)
    case offender.case_allocation
    when 'NPS'
      nps_calculation(offender)
    when 'CRC'
      'Prison'
    else
      'Unknown'
    end
  end

  def self.nps_calculation(offender)
    return 'No release date' if offender.release_date.nil?

    offender.tier == 'A' || offender.tier == 'B' ? 'Probation' : 'Prison'
  end
end
