# frozen_string_literal: true

class ViewHandoverEmailAddressesSummary
  def execute(offenders)
    grouped_offenders = offenders.group_by { |offender| offender_category(offender) }

    empty_groups.merge(grouped_offenders.transform_values(&:count))
  end

  def offender_category(offender)
    case_info = CaseInformation.find_by(nomis_offender_id: offender.offender_no)

    return :missing_delius_record if missing_delius_record?(case_info)
    return :missing_team_link if missing_team_link?(case_info)
    return :missing_team_information if missing_team_information?(case_info)
    return :missing_local_delivery_unit if missing_local_delivery_unit?(case_info)
    return :missing_local_delivery_unit_email if missing_email?(case_info)

    :has_email_address
  end

  def missing_delius_record?(case_info)
    case_info.nil?
  end

  def missing_team_link?(case_info)
    case_info.team_id.blank?
  end

  def missing_team_information?(case_info)
    case_info.team.blank?
  end

  def missing_local_delivery_unit?(case_info)
    case_info.team.local_divisional_unit_id.blank?
  end

  def missing_email?(case_info)
    case_info.team.local_divisional_unit.email_address.blank?
  end

  def empty_groups
    {
      has_email_address: 0,
      missing_delius_record: 0,
      missing_team_link: 0,
      missing_team_information: 0,
      missing_local_delivery_unit: 0,
      missing_local_delivery_unit_email: 0
    }
  end
end
