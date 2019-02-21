# :nocov:
class PomMailer < GovukNotifyRails::Mailer
  # TODO: Add POM email addresses
  # rubocop:disable Metrics/MethodLength
  def new_allocation_email(pom, offender, message)
    return unless active?

    message = "Additional information: #{message}" if message.present?

    set_template('9679ea4c-1495-4fa6-a00b-630de715e315')
    set_personalisation(
      email_subject: 'New OMIC allocation',
      pom_name: pom.first_name.capitalize,
      offender_name: offender.full_name,
      nomis_offender_id: offender.offender_no,
      message: message
    )

    mail(to: 'kath.pobee-norris@digital.justice.gov.uk')
  end
  # rubocop:enable Metrics/MethodLength

  def deallocation_email(previous_pom, new_pom, offender)
    return unless active?

    set_template('cd628495-6e7a-448e-b4ad-4d49d4d8567d')

    set_personalisation(
      email_subject: 'OMIC case reallocation',
      previous_pom_name: previous_pom.first_name.capitalize,
      new_pom_name: new_pom.first_name.capitalize,
      offender_name: offender.full_name,
      prison: new_pom.agency_id
    )

    mail(to: '')
  end

private

  def active?
    Rails.configuration.notify_api_key.present?
  end
end
# :nocov:
