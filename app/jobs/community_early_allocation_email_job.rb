# frozen_string_literal: true

class CommunityEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailer

  def perform(prison, offender_no, encoded_pdf)
    offender = OffenderService.get_offender(offender_no)
    allocation = AllocationVersion.find_by!(nomis_offender_id: offender_no)
    pom = PrisonOffenderManagerService.get_pom(prison, allocation.primary_pom_nomis_id)
    pdf = Base64.decode64 encoded_pdf
    PomMailer.community_early_allocation(email: offender.ldu.email_address,
                                         prisoner_name: offender.full_name,
                                         prisoner_number: offender.offender_no,
                                         pom_name: allocation.primary_pom_name,
                                         pom_email: pom.emails.first,
                                         prison_name: PrisonService.name_for(prison),
                                         pdf: pdf).deliver_now
  end
end
