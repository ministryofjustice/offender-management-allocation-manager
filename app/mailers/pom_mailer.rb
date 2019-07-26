# frozen_string_literal: true

class PomMailer < GovukNotifyRails::Mailer
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

  # rubocop:disable Metrics/ParameterLists
  def allocate_coworking_pom(
    pom_email:, message:, pom_name:, coworking_pom_name:, url:,
    offender_name:, nomis_offender_id:
  )
    set_template('a76f44a0-e214-4967-bfe3-4564d28e2951')

    message = "Additional information: #{message}" if message.present?

    set_personalisation(message: message || '',
                        pom_name: pom_name,
                        coworking_pom_name: coworking_pom_name,
                        url: url,
                        offender_name: offender_name,
                        nomis_offender_id: nomis_offender_id)

    mail(to: pom_email)
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/ParameterLists
  def secondary_allocation_email(
    message:, pom_name:, offender_name:, nomis_offender_id:,
    responsible_pom_name:, pom_email:, url:, responsibility:
)
    message = "Additional information: #{message}" if message.present?
    set_template('8d63ef1a-8f85-47ec-875c-a8bd3a22bb0d')
    set_personalisation(
      pom_name: pom_name,
      url: url,
      responsibility: responsibility,
      offender_name: offender_name,
      nomis_offender_id: nomis_offender_id,
      responsible_pom_name: responsible_pom_name,
      message: message || ''
    )

    mail(to: pom_email)
  end
  # rubocop:enable Metrics/ParameterLists

  def new_prison_allocation_email(prison)
    set_template('651da525-7564-4f04-85ff-b0343fb7c47d')
    set_personalisation(
      email_subject: 'New Allocation',
      prison: PrisonService.name_for(prison)
    )

    mail(to: ENV['SUPPORT_EMAIL'])
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
