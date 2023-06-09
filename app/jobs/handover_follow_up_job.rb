class HandoverFollowUpJob < ApplicationJob
  queue_as :default
  include PomHelper

  def perform(ldu)
    today = Time.zone.today
    active_prison_codes = Prison.active.map(&:code)

    offenders = get_ldu_offenders(ldu)
                  .select do |o|
                    o.sentenced? && o.handover_start_date.present? &&
                      active_prison_codes.include?(o.prison_id) && o.handover_start_date == today - 1.week
                  end

    offenders.each do |offender|
      allocation = AllocationHistory.find_by(nomis_offender_id: offender.offender_no)

      if allocation.present? && allocation.active?
        prison = Prison.find(offender.prison_id)
        pom = prison.get_single_pom(allocation.primary_pom_nomis_id)
        pom_name = full_name(pom)
        pom_email = pom.email_address
      else
        # There is no POM allocated
        pom_name = 'This offender does not have an allocated POM'
        pom_email = ''
      end

      offender_type = offender.indeterminate_sentence? ? 'Indeterminate' : 'Determinate'

      CommunityMailer.with(
        nomis_offender_id: offender.offender_no,
        offender_name: offender.full_name,
        offender_crn: offender.crn,
        sentence_type: offender_type,
        ldu_email: offender.ldu_email_address,
        prison: Prison.find(offender.prison_id).name,
        start_date: offender.handover_start_date,
        responsibility_handover_date: offender.responsibility_handover_date,
        pom_name: pom_name,
        pom_email: pom_email
      ).urgent_pipeline_to_community.deliver_now
    end
  end

private

  def get_ldu_offenders(ldu)
    ldu.case_information.where(com_name: nil).map(&:nomis_offender_id).map { |offender_id|
      OffenderService.get_offender(offender_id)
    }.compact
  end
end
