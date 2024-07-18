class EmailHistoryMailObserver
  def self.delivered_email(message)
    case message.govuk_notify_reference
    when 'email.pom.responsibility_override'
      EmailHistory.create!(
        event: EmailHistory::RESPONSIBILITY_OVERRIDE,
        nomis_offender_id: message.govuk_notify_personalisation[:prisoner_number],
        prison: Prison.find_by(name: message.govuk_notify_personalisation[:prison_name]).code,
        email: message.to.first,
        name: message.to.first,
      )
    when 'email.community.open_prison_supporting_com_needed'
      EmailHistory.create!(
        event: EmailHistory::OPEN_PRISON_SUPPORTING_COM_NEEDED,
        nomis_offender_id: message.govuk_notify_personalisation[:prisoner_number],
        prison: Prison.find_by(name: message.govuk_notify_personalisation[:prison_name]).code,
        email: message.to.first,
        name: message.to.first,
      )
    when 'email.community.urgent_pipeline_to_community'
      EmailHistory.create!(
        event: EmailHistory::URGENT_PIPELINE_TO_COMMUNITY,
        nomis_offender_id: message.govuk_notify_personalisation[:noms_no],
        prison: Prison.find_by(name: message.govuk_notify_personalisation[:prison_name]).code,
        email: message.to.first,
        name: message.to.first,
      )
    when 'email.community.assign_com_less_than_10_months'
      EmailHistory.create!(
        event: EmailHistory::ASSIGN_COM_LESS_THAN_10_MONTHS,
        nomis_offender_id: message.govuk_notify_personalisation[:prisoner_number],
        prison: Prison.find_by(name: message.govuk_notify_personalisation[:prison_name]).code,
        email: message.to.first,
        name: message.to.first,
      )
    end
  end
end
