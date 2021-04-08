# frozen_string_literal: true

class CommunityMailer < GovukNotifyRails::Mailer
  def pipeline_to_community(ldu_name:, ldu_email:, csv_data:)
    set_template('6e2f7565-a0e3-4fd7-b814-ee9dd5148924')
    set_personalisation(ldu_name: ldu_name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(csv_data), true))

    mail(to: ldu_email)
  end

  def pipeline_to_community_no_handovers(ldu_name:, ldu_email:)
    set_template('bac3628c-aabe-4043-af11-147467720e04')
    set_personalisation(ldu_name: ldu_name)

    mail(to: ldu_email)
  end

  def urgent_pipeline_to_community(nomis_offender_id:, offender_name:, offender_crn:, ldu_email:, prison:,
                                   sentence_type:, start_date:, responsibility_handover_date:, pom_name:, pom_email:)
    set_template('d7366b11-c93e-48de-824f-cb80a9778e71')

    set_personalisation(
      email: ldu_email,
      name: offender_name,
      crn: offender_crn,
      sentence_type: sentence_type,
      noms_no: nomis_offender_id,
      prison_name: prison,
      start_date: start_date,
      responsibility_handover_date: responsibility_handover_date,
      pom_name: pom_name,
      pom_email: pom_email
    )

    mail(to: ldu_email)
  end

  def open_prison_supporting_com_needed(prisoner_name:, prisoner_number:, prisoner_crn:, prison_name:, ldu_email:)
    set_template('51eea8d1-6c73-4b86-bac0-f74ad5573b43')

    set_personalisation(
      prisoner_name: prisoner_name,
      prisoner_number: prisoner_number,
      prisoner_crn: prisoner_crn,
      prison_name: prison_name
    )

    mail(to: ldu_email)
  end

  def open_prison_prepolicy_responsible_com_needed(
    prisoner_name:,
    prisoner_number:,
    prisoner_crn:,
    previous_pom_name:,
    previous_pom_email:,
    prison_name:,
    previous_prison_name:,
    email:
  )
    set_template('e517ddc9-5854-462e-b9a1-f67c97ad5b63')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        prisoner_crn: prisoner_crn,
                        previous_pom_name: previous_pom_name,
                        previous_pom_email: previous_pom_email,
                        prison_name: prison_name,
                        previous_prison_name: previous_prison_name)
    mail(to: email)
  end

  def assign_com_less_than_10_months email:, prisoner_name:, prisoner_number:, crn_number:, prison_name:
    set_template('6cae6890-6a5a-4ceb-82bd-43c8b43fc639')

    set_personalisation(prisoner_number: prisoner_number,
                        prison_name: prison_name,
                        crn_number: crn_number,
                        prisoner_name: prisoner_name)
    mail(to: email)
  end
end
