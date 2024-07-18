class EmailHistoryMailObserver
  def self.delivered_email(message)
    case message.govuk_notify_template
    when PomMailer::RESPONSIBILITY_OVERRIDE_TEMPLATE
      nomis_offender_id = message.govuk_notify_personalisation[:prisoner_number]
      prison = Prison.find_by(name: message.govuk_notify_personalisation[:prison_name]).code
      email = message.to.first
      name = email

      EmailHistory.responsibility_override.create!(
        nomis_offender_id:,
        prison:,
        email:,
        name:
      )
    end
  end
end
