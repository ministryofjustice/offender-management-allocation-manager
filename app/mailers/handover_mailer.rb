class HandoverMailer < GovukNotifyRails::Mailer
  def upcoming_handover_window(email:,
                               nomis_offender_id:,
                               full_name_ordered:,
                               first_name:,
                               handover_date:,
                               service_provider:,
                               release_date:)
    set_template('7114ad9e-e71a-4424-a884-bcc72bd1a569')
    set_personalisation(nomis_offender_id: nomis_offender_id,
                        full_name_ordered: full_name_ordered,
                        first_name: first_name,
                        handover_date: handover_date,
                        is_standard: service_provider == 'NPS' ? 'no' : 'yes',
                        is_enhanced: service_provider == 'NPS' ? 'yes' : 'no',
                        release_date: release_date)
    mail(to: email)
  end

  def handover_date(email:,
                    nomis_offender_id:,
                    first_name:,
                    full_name_ordered:,
                    release_date:,
                    com_name:,
                    com_email:,
                    service_provider:)
    set_template('95ddd96c-23f9-4066-b033-d4a1d83b702e')
    set_personalisation(nomis_offender_id: nomis_offender_id,
                        full_name_ordered: full_name_ordered,
                        first_name: first_name,
                        com_name: com_name,
                        com_email: com_email,
                        is_standard: service_provider == 'NPS' ? 'no' : 'yes',
                        is_enhanced: service_provider == 'NPS' ? 'yes' : 'no',
                        release_date: release_date)
    mail(to: email)
  end

  def com_allocation_overdue(email:,
                             nomis_offender_id:,
                             full_name_ordered:,
                             handover_date:,
                             release_date:,
                             ldu_name:,
                             ldu_email:,
                             service_provider:)
    set_template('21d34a34-f2ec-42c2-82b3-720899b58a3b')

    ldu_information = ''
    ldu_information += "LDU: #{ldu_name}\n" if ldu_name.present?
    ldu_information += "LDU email: #{ldu_email}\n" if ldu_email.present?

    set_personalisation(nomis_offender_id: nomis_offender_id,
                        full_name_ordered: full_name_ordered,
                        handover_date: handover_date,
                        release_date: release_date,
                        is_standard: service_provider == 'NPS' ? 'no' : 'yes',
                        is_enhanced: service_provider == 'NPS' ? 'yes' : 'no',
                        ldu_information: ldu_information,
                        has_ldu_email: ldu_email.present?,
                        missing_ldu_email: ldu_email.blank?)
    mail(to: email)
  end
end
