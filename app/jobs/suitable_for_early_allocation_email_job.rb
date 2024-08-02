# frozen_string_literal: true

class SuitableForEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailers

  self.log_arguments = false

  EQUIP_URL = 'https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777'

  def perform(offender_no)
    allocation = AllocationHistory.where(nomis_offender_id: offender_no).first
    return if allocation.nil?

    prisoner = OffenderService.get_offender(offender_no)

    if !prisoner.nil? && prisoner.within_early_allocation_window?

      already_emailed = EmailHistory.sent_within_current_sentence(prisoner, EmailHistory::SUITABLE_FOR_EARLY_ALLOCATION)

      if already_emailed.empty?
        prison = Prison.find(prisoner.prison_id)
        pom = prison.get_single_pom(allocation.primary_pom_nomis_id)
        EarlyAllocationMailer.with(
          email: pom.email_address,
          prisoner_name: prisoner.full_name,
          prisoner_number: prisoner.offender_no,
          prison_name: prison.name,
          start_page_link: Rails.application.routes.url_helpers.prison_prisoner_early_allocations_url(
            prison_id: prisoner.prison_id,
            prisoner_id: prisoner.offender_no
          ),
          equip_guidance_link: EQUIP_URL
        ).review_early_allocation.deliver_now
      end
    end
  end
end
