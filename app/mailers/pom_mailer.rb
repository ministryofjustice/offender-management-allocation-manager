# frozen_string_literal: true

class PomMailer < GovukNotifyRails::Mailer
  def new_allocation_email(params = {})
    message_detail = "Additional information: #{params[:message]}" if params[:message].present?
    set_template('9fbba261-45c7-4f99-aaf2-46570c6eac73')
    set_personalisation(
      email_subject: 'New OMIC allocation',
      pom_name: params[:pom_name],
      responsibility: params[:responsibility],
      offender_name: params[:offender_name],
      nomis_offender_id: params[:offender_no],
      message: message_detail || '',
      url: params[:url],
      last_oasys_completed: params[:further_info]&.fetch(:last_oasys_completed, ''),
      handover_start_date: params[:further_info]&.fetch(:handover_start_date, ''),
      handover_completion_date: params[:further_info]&.fetch(:handover_completion_date, ''),
      com_name: params[:further_info]&.fetch(:com_name, ''),
      com_email: params[:further_info]&.fetch(:com_email, '')
    )

    Rails.logger.info("MO-1223: PomMailer.new_allocation_email, URL:#{params[:url]}") # Temporary to debug an issue where URL is getting split into 2 lines
    mail(to: params[:pom_email])
  end

  def responsibility_override(
    message:,
    prisoner_number:,
    prisoner_name:,
    prison_name:,
    email:
  )
    set_template('ca952ba5-58b5-4e2d-8d87-60590d76560c')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        reason: message,
                        prison_name: prison_name)
    mail(to: email)
  end

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

  def deallocate_coworking_pom(email_address:, pom_name:,
                               secondary_pom_name:, nomis_offender_id:,
                               offender_name:, url:)
    set_template('bbdd094b-037b-424d-8b9b-ee310e291c9e')

    set_personalisation(pom_name: pom_name,
                        email_address: email_address,
                        secondary_pom_name: secondary_pom_name,
                        nomis_offender_id: nomis_offender_id,
                        offender_name: offender_name,
                        url: url)

    mail(to: email_address)
  end

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

  def new_prison_allocation_email(prison)
    set_template('651da525-7564-4f04-85ff-b0343fb7c47d')
    set_personalisation(
      email_subject: 'New Allocation',
      prison: Prison.find(prison).name
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
      url: params[:url],
      last_oasys_completed: params[:further_info]&.fetch(:last_oasys_completed, ''),
      handover_start_date: params[:further_info]&.fetch(:handover_start_date, ''),
      handover_completion_date: params[:further_info]&.fetch(:handover_completion_date, ''),
      com_name: params[:further_info]&.fetch(:com_name, ''),
      com_email: params[:further_info]&.fetch(:com_email, '')
    )

    mail(to: params[:previous_pom_email])
  end

  def offender_deallocated(email:,
                           pom_name:,
                           offender_name:,
                           nomis_offender_id:,
                           prison_name:,
                           url:)
    set_template('1df51f52-512d-434b-9088-50eacaa47c59')
    set_personalisation(pom_name: pom_name,
                        offender_name: offender_name,
                        nomis_offender_id: nomis_offender_id,
                        prison_name: prison_name,
                        url: url)

    mail(to: email)
  end
end
