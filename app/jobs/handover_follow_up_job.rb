class HandoverFollowUpJob < ApplicationJob
  queue_as :default

  def perform(date)
    ldus = LocalDivisionalUnit.with_email_address
    active_prison_codes = Prison.active.map(&:code)

    ldus.each do |ldu|
      offenders = ldu.teams.map { |team| team.case_information.where(com_name: nil).map(&:nomis_offender_id) }.flatten
                  .map { |off_id| OffenderService.get_offender(off_id) }
                    .select { |o|
                      !o.nil? && o.sentenced? && o.handover_start_date.present? &&
                        active_prison_codes.include?(o.prison_id) && o.handover_start_date == date - 1.week
                    }

      offenders.each do |offender|
        allocation = Allocation.where(nomis_offender_id: offender.offender_no).first
        pom = PrisonOffenderManagerService.get_pom_at(offender.prison_id, allocation.primary_pom_nomis_id)
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
          pom_name: pom.full_name,
          pom_email: pom.email_address
        ).deliver_now
      end
    end
  end
end
