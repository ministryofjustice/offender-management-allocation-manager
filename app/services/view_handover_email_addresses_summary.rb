# frozen_string_literal: true

# See how many of the given offenders are missing an email address for handover, and why
#
# Use this via the rake task:
#   rails handover_email_summary_by_prison [PRISON_CODE]
#
# Or in the Rails console:
#   prison = Prison.new(PRISON_CODE)
#   offenders = prison.offenders
#   pp ViewHandoverEmailAddressesSummary.new.execute(offenders)

class ViewHandoverEmailAddressesSummary
  def execute(offenders)
    grouped_offenders = offenders.group_by { |offender| offender_category(offender) }

    empty_groups.merge(grouped_offenders.transform_values(&:count))
  end

  def offender_category(offender)
    case_info = CaseInformation.find_by(nomis_offender_id: offender.offender_no)

    if missing_delius_record?(case_info)
      :missing_delius_record
    elsif missing_team_link?(case_info)
      :missing_team_link
    elsif missing_team_information?(case_info)
      :missing_team_information
    elsif missing_local_divisional_unit?(case_info)
      :missing_local_divisional_unit
    elsif missing_email?(case_info)
      :missing_local_divisional_unit_email
    else
      :has_email_address
    end
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

  def missing_local_divisional_unit?(case_info)
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
      missing_local_divisional_unit: 0,
      missing_local_divisional_unit_email: 0,
    }
  end
end
