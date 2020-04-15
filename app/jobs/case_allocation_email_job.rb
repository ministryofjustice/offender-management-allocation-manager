# frozen_string_literal: true

class CaseAllocationEmailJob < ApplicationJob
  queue_as :mailer

  def perform(email:, ldu:, nomis_offender_id:, message:, notice:)
    prisoner = prisoner(nomis_offender_id)

    PomMailer.manual_case_info_update(email_address: email,
                                      ldu_name: ldu,
                                      offender_name: prisoner.full_name,
                                      nomis_offender_id: nomis_offender_id,
                                      offender_dob: prisoner.date_of_birth,
                                      prison_name: PrisonService.name_for(prisoner.prison_id),
                                      message: message,
                                      spo_notice: notice).deliver_now
  end
end
