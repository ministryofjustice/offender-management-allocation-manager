class HandoverFollowUpJob < ApplicationJob
  queue_as :default

  def perform(ldu)
    today = Time.zone.today
    active_prisons = Prison.active
    active_prison_codes = active_prisons.map(&:code)

    offenders = ldu.teams.map { |team| team.case_information.where(com_name: nil).map(&:nomis_offender_id) }.flatten
                .map { |off_id| OffenderService.get_offender(off_id) }
                  .select { |o|
                    !o.nil? && o.sentenced? && o.handover_start_date.present? &&
                      active_prison_codes.include?(o.prison_id) && o.handover_start_date == today - 1.week
                  }

    offenders.each do |offender|
      allocation = Allocation.find_by(nomis_offender_id: offender.offender_no)

      if allocation.present? && allocation.active?
        pom = PrisonOffenderManagerService.get_pom_at(offender.prison_id, allocation.primary_pom_nomis_id)
        pom_name = pom.full_name
        pom_email = pom.email_address
      else
        # There is no POM allocated
        pom_name = 'This offender does not have an allocated POM'
        pom_email = ''
      end

      offender_type = offender.indeterminate_sentence? ? 'Indeterminate' : 'Determinate'

      CommunityMailer.urgent_pipeline_to_community(
        nomis_offender_id: offender.offender_no,
        offender_name: offender.full_name,
        offender_crn: offender.crn,
        sentence_type: offender_type,
        ldu_email: offender.ldu_email_address,
        prison: PrisonService.name_for(offender.prison_id),
        start_date: offender.handover_start_date,
        responsibility_handover_date: offender.responsibility_handover_date,
        pom_name: pom_name,
        pom_email: pom_email
      ).deliver_now
    end
  end
end
