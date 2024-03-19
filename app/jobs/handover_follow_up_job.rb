class HandoverFollowUpJob < ApplicationJob
  queue_as :default

  def perform(ldu)
    today = Time.zone.today
    active_prison_codes = Prison.active.map(&:code)

    offenders = get_ldu_offenders(ldu)
                  .select do |o|
                    o.sentenced? && o.handover_start_date.present? &&
                      active_prison_codes.include?(o.prison_id) && o.handover_start_date == today - 1.week
                  end

    offenders.each do |offender|
      CommunityMailer
        .with(FollowUpEmailDetails.for(offender:))
        .urgent_pipeline_to_community
    end
  end

private

  def get_ldu_offenders(ldu)
    ldu.case_information.where(com_name: nil).map(&:nomis_offender_id).map { |offender_id|
      OffenderService.get_offender(offender_id)
    }.compact
  end
end
