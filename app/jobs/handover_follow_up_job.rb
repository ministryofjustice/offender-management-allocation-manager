class HandoverFollowUpJob < ApplicationJob
  queue_as :mailers

  # Email content can become stale; avoid retrying for days
  sidekiq_options retry: 10

  def perform(ldu)
    offenders_due_handover_follow_up = OffenderService
      .get_offenders(ldu.case_information.without_com.pluck(:nomis_offender_id))
      .select(&:should_send_handover_follow_up_email?)

    offenders_due_handover_follow_up.each do |offender|
      CommunityMailer
        .with(FollowUpEmailDetails.for(offender:))
        .urgent_pipeline_to_community.deliver_later
    end
  end
end
