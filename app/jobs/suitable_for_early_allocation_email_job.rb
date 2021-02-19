# frozen_string_literal: true

class SuitableForEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailers

  EQUIP_URL = 'https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777'

  def perform(offender_no)
    allocation = Allocation.where(nomis_offender_id: offender_no).first
    return if allocation.nil?

    prisoner = OffenderService.get_offender(offender_no)

    if !prisoner.nil? && prisoner.within_early_allocation_window?

      already_emailed = EmailHistory.sent_within_current_sentence(prisoner,  EmailHistory::SUITABLE_FOR_EARLY_ALLOCATION)

      if already_emailed.empty?

        pom = PrisonOffenderManagerService.get_pom_at(prisoner.prison_id, allocation.primary_pom_nomis_id)
        EarlyAllocationMailer.review_early_allocation(
          email: pom.email_address,
          prisoner_name: prisoner.full_name,
          start_page_link: Rails.application.routes.url_helpers.prison_prisoner_early_allocations_url(
            prison_id: prisoner.prison_id,
            prisoner_id: prisoner.offender_no),
          equip_guidance_link: EQUIP_URL).deliver_now

        EmailHistory.create! nomis_offender_id: prisoner.offender_no,
                             name: pom.full_name,
                             email: pom.email_address,
                             event: EmailHistory::SUITABLE_FOR_EARLY_ALLOCATION,
                             prison: prisoner.prison_id
      end
    end
  end
end
