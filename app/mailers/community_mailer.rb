# frozen_string_literal: true

class CommunityMailer < ApplicationMailer
  def pipeline_to_community
    set_template('6e2f7565-a0e3-4fd7-b814-ee9dd5148924')
    set_personalisation(ldu_name: params.fetch(:ldu_name),
                        link_to_document: Notifications.prepare_upload(StringIO.new(params.fetch(:csv_data)), true))

    mail(to: params.fetch(:ldu_email))
  end

  def pipeline_to_community_no_handovers
    set_template('bac3628c-aabe-4043-af11-147467720e04')
    set_personalisation(ldu_name: params.fetch(:ldu_name))

    mail(to: params.fetch(:ldu_email))
  end

  def urgent_pipeline_to_community
    set_template('d7366b11-c93e-48de-824f-cb80a9778e71')

    set_personalisation(
      email: params.fetch(:ldu_email),
      name: params.fetch(:offender_name),
      crn: params.fetch(:offender_crn),
      sentence_type: params.fetch(:sentence_type),
      noms_no: params.fetch(:nomis_offender_id),
      prison_name: params.fetch(:prison),
      start_date: params.fetch(:start_date),
      responsibility_handover_date: params.fetch(:responsibility_handover_date),
      pom_name: params.fetch(:pom_name),
      pom_email: params.fetch(:pom_email),
    )
    mail(to: params.fetch(:ldu_email))
  end

  def open_prison_supporting_com_needed
    set_template('51eea8d1-6c73-4b86-bac0-f74ad5573b43')

    set_personalisation(**params.slice(:prisoner_name, :prisoner_number, :prisoner_crn, :prison_name, :email_history_name))

    mail(to: params.fetch(:ldu_email))
  end

  def assign_com_less_than_10_months
    set_template('6cae6890-6a5a-4ceb-82bd-43c8b43fc639')
    params[:nomis_offender_id] = params.fetch(:prisoner_number)
    set_personalisation(**params.slice(:prisoner_number, :nomis_offender_id, :prison_name, :crn_number, :prisoner_name))

    mail(to: params.fetch(:email))
  end
end
