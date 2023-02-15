class HandoverMailer < GovukNotifyRails::Mailer
  def upcoming_handover_window(email:,
                               nomis_offender_id:,
                               full_name_ordered:,
                               first_name:,
                               handover_date:,
                               service_provider:,
                               release_date:)
    set_template('38f1d962-7b36-44d2-a78d-c6fb8aaaffcb')
    set_personalisation(nomis_offender_id: nomis_offender_id,
                        full_name_ordered: full_name_ordered,
                        first_name: first_name,
                        handover_date: handover_date,
                        service_provider: service_provider,
                        is_nps: service_provider == 'NPS' ? 'yes' : 'no',
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
    set_template('7eaafff6-dae8-4eb2-bca5-bb530e0f1078')
    set_personalisation(nomis_offender_id: nomis_offender_id,
                        full_name_ordered: full_name_ordered,
                        first_name: first_name,
                        com_name: com_name,
                        com_email: com_email,
                        is_nps: service_provider == 'NPS' ? 'yes' : 'no',
                        is_crc: service_provider == 'CRC' ? 'yes' : 'no',
                        release_date: release_date)
    mail(to: email)
  end
end
