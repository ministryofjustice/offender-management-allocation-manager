# frozen_string_literal: true

class AutoEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailer

  def perform(prison, offender_no, encoded_pdf)
    offender = OffenderService.get_offender(offender_no)
    pdf = Base64.decode64 encoded_pdf
    PomMailer.auto_early_allocation(email: offender.ldu.email_address,
                                    prisoner_name: offender.full_name,
                                    prisoner_number: offender.offender_no,
                                    prison_name: PrisonService.name_for(prison),
                                    pdf: pdf).deliver_now
  end
end
