# frozen_string_literal: true

# rubocop:disable Metrics/ParameterLists
class PomMailer < GovukNotifyRails::Mailer
  def new_allocation_email(params = {})
    message_detail = "Additional information: #{params[:message]}" if params[:message].present?
    set_template('9679ea4c-1495-4fa6-a00b-630de715e315')
    set_personalisation(
      email_subject: 'New OMIC allocation',
      pom_name: params[:pom_name],
      responsibility: params[:responsibility],
      offender_name: params[:offender_name],
      nomis_offender_id: params[:offender_no],
      message: message_detail || '',
      url: params[:url]
    )

    mail(to: params[:pom_email])
  end

  def auto_early_allocation(email:, prisoner_name:, prisoner_number:, prison_name:, pdf:)
    set_template('dfaeb1b1-26c3-4646-8ef4-1f0ebd18e2e7')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        prison_name: prison_name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(pdf)))

    mail(to: email)
  end

  def community_early_allocation(email:, prisoner_name:, prisoner_number:, pom_name:, pom_email:, prison_name:, pdf:)
    set_template('5e546d65-57ff-49e1-8fae-c955a7b1da80')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        pom_name: pom_name,
                        pom_email_address: pom_email,
                        prison_name: prison_name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(pdf)))

    mail(to: email)
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

  def responsibility_override_open_prison(
    prisoner_name:,
    prisoner_number:,
    responsible_pom_name:,
    responsible_pom_email:,
    prison_name:,
    previous_prison_name:,
    email:
  )
    set_template('e517ddc9-5854-462e-b9a1-f67c97ad5b63')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        responsible_pom_name: responsible_pom_name,
                        responsible_pom_email: responsible_pom_email,
                        prison_name: prison_name,
                        previous_prison_name: previous_prison_name)
    mail(to: email)
  end
  # rubocop:enable Metrics/ParameterLists

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

  def manual_case_info_update(
    email_address:, ldu_name:, offender_name:, nomis_offender_id:, offender_dob:, prison_name:, message:, spo_notice:
  )
    set_template('3a795dc1-6e8a-4e7b-93d7-f30813389d84')

    set_personalisation(
      ldu_name: ldu_name,
      offender_name: offender_name,
      nomis_offender_id: nomis_offender_id,
      offender_dob: offender_dob,
      prison_name: prison_name,
      message: message,
      spo_notice: spo_notice
    )

    mail(to: email_address)
  end
end
# rubocop:enable Metrics/ParameterLists
