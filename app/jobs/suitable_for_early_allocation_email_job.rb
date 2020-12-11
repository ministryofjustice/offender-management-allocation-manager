# frozen_string_literal: true

class SuitableForEarlyAllocationEmailJob < ApplicationJob
  queue_as :mailer

  EQUIP_URL = 'https://equip-portal.rocstac.com/CtrlWebIsapi.dll/?__id=webDiagram.show&map=0%3A9A63E167DE4B400EA07F81A9271E1944&dgm=4F984B45CBC447B1A304B2FFECABB777'

  def perform
    offenders = EarlyAllocation.suitable_offenders_pre_referral_window

    offenders.each do |offender_no|
      allocation = Allocation.where(nomis_offender_id: offender_no).first
      next if allocation.nil?

      prisoner = OffenderService.get_offender(offender_no)
      if !prisoner.nil? && eligible_today?(prisoner)
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

private

  def eligible_today?(offender)
    [
      offender.tariff_date,
      offender.parole_eligibility_date,
      offender.parole_review_date,
      offender.automatic_release_date,
      offender.conditional_release_date
    ].compact.min == Time.zone.today + 18.months
  end
end
