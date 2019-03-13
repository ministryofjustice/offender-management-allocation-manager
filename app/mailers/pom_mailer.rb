class PomMailer < GovukNotifyRails::Mailer
  # rubocop:disable Metrics/MethodLength
  #  rubocop:disable Metrics/ParameterLists
  def new_allocation_email(pom_name, pom_email, offender_name, offender_no, message, url)
    message = "Additional information: #{message}" if message.present?
    set_template('9679ea4c-1495-4fa6-a00b-630de715e315')
    set_personalisation(
      email_subject: 'New OMIC allocation',
      pom_name: pom_name,
      offender_name: offender_name,
      nomis_offender_id: offender_no,
      message: message,
      url: url
    )

    mail(to: pom_email)
  end

  # rubocop:disable Metrics/LineLength
  def deallocation_email(previous_pom_name, previous_pom_email, new_pom_name, offender_name, offender_no, prison, url)
    set_template('cd628495-6e7a-448e-b4ad-4d49d4d8567d')

    set_personalisation(
      email_subject: 'OMIC case reallocation',
      previous_pom_name: previous_pom_name,
      new_pom_name: new_pom_name,
      offender_name: offender_name,
      nomis_offender_id: offender_no,
      prison: prison,
      url: url
    )

    mail(to: previous_pom_email)
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ParameterLists
#  rubocop:enable Metrics/LineLength
