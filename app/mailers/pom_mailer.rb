class PomMailer < GovukNotifyRails::Mailer
  # rubocop:disable Metrics/MethodLength
  def new_allocation_email(params = {})
    message = "Additional information: #{params[:message]}" if params[:message].present?
    set_template('9679ea4c-1495-4fa6-a00b-630de715e315')
    set_personalisation(
      email_subject: 'New OMIC allocation',
      pom_name: params[:pom_name],
      responsibility: params[:responsibility],
      offender_name: params[:offender_name],
      nomis_offender_id: params[:offender_no],
      message: message || '',
      url: params[:url]
    )

    mail(to: params[:pom_email])
  end

  def deallocation_email(params = {})
    set_template('cd628495-6e7a-448e-b4ad-4d49d4d8567d')

    set_personalisation(
      email_subject: 'OMIC case reallocation',
      previous_pom_name: params[:previous_pom_name],
      responsibility: params[:responsibility],
      new_pom_name: params[:new_pom_name],
      offender_name: params[:offender_name],
      nomis_offender_id: params[:offender_no],
      prison: params[:prison],
      url: params[:url]
    )

    mail(to: params[:previous_pom_email])
  end
end
# rubocop:enable Metrics/MethodLength
