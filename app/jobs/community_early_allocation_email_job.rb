# frozen_string_literal: true

class CommunityEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailers

  self.log_arguments = false

  def perform(prison, offender_no, encoded_pdf)
    offender = OffenderService.get_offender(offender_no)
    allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)
    pom = prison.get_single_pom(allocation.primary_pom_nomis_id)
    pdf = Base64.decode64 encoded_pdf
    EarlyAllocationMailer.with(email: offender.ldu_email_address,
                               prisoner_name: offender.full_name,
                               prisoner_number: offender.offender_no,
                               pom_name: allocation.primary_pom_name,
                               pom_email: pom.email_address,
                               prison_name: prison.name,
                               pdf: pdf).community_early_allocation.deliver_now
  end
end
