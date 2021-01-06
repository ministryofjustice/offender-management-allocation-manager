# frozen_string_literal: true

# This is needed as a job as the (binary) PDF has to be
# done with deliver_now
class AutoEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailer

  def perform(prison, offender_no, encoded_pdf)
    offender = OffenderService.get_offender(offender_no)
    pdf = Base64.decode64 encoded_pdf
    EarlyAllocationMailer.auto_early_allocation(email: offender.ldu_email_address,
                                    prisoner_name: offender.full_name,
                                    prisoner_number: offender.offender_no,
                                    prison_name: PrisonService.name_for(prison),
                                    pdf: pdf).deliver_now
    EmailHistory.create! nomis_offender_id: offender.offender_no,
                         name: offender.ldu_name,
                         email: offender.ldu_email_address,
                         event: EmailHistory::AUTO_EARLY_ALLOCATION,
                         prison: prison
  end
end
