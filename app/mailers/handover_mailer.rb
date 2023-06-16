class HandoverMailer < ApplicationMailer
  set_mailer_tag 'handover_reminder'

  def upcoming_handover_window
    set_template('7114ad9e-e71a-4424-a884-bcc72bd1a569')
    set_personalisation(nomis_offender_id: params.fetch(:nomis_offender_id),
                        full_name_ordered: params.fetch(:full_name_ordered),
                        first_name: params.fetch(:first_name),
                        handover_date: params.fetch(:handover_date),
                        is_standard: params.fetch(:enhanced_handover) ? 'no' : 'yes',
                        is_enhanced: params.fetch(:enhanced_handover) ? 'yes' : 'no',
                        release_date: params.fetch(:release_date))
    mail(to: params.fetch(:email))
  end

  def handover_date
    set_template('95ddd96c-23f9-4066-b033-d4a1d83b702e')
    set_personalisation(nomis_offender_id: params.fetch(:nomis_offender_id),
                        full_name_ordered: params.fetch(:full_name_ordered),
                        first_name: params.fetch(:first_name),
                        com_name: params.fetch(:com_name),
                        com_email: params[:com_email] || 'Unknown',
                        is_standard: params.fetch(:enhanced_handover) ? 'no' : 'yes',
                        is_enhanced: params.fetch(:enhanced_handover) ? 'yes' : 'no',
                        release_date: params.fetch(:release_date))
    mail(to: params.fetch(:email))
  end

  def com_allocation_overdue
    ldu_name = params.fetch(:ldu_name)
    ldu_email = params.fetch(:ldu_email)
    ldu_information = ''
    ldu_information += "LDU: #{ldu_name}\n" if ldu_name.present?
    ldu_information += "LDU email: #{ldu_email}\n" if ldu_email.present?

    set_template('21d34a34-f2ec-42c2-82b3-720899b58a3b')
    set_personalisation(nomis_offender_id: params.fetch(:nomis_offender_id),
                        full_name_ordered: params.fetch(:full_name_ordered),
                        handover_date: params.fetch(:handover_date),
                        release_date: params.fetch(:release_date),
                        is_standard: params.fetch(:enhanced_handover) ? 'no' : 'yes',
                        is_enhanced: params.fetch(:enhanced_handover) ? 'yes' : 'no',
                        ldu_information: ldu_information,
                        has_ldu_email: ldu_email.present?,
                        missing_ldu_email: ldu_email.blank?)
    mail(to: params.fetch(:email))
  end
end
