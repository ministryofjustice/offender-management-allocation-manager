class HandoverMaintenanceService
  class << self
    def chase_ldu(mpc_offender)
      db_offender = mpc_offender.model
      handover = db_offender.calculated_handover_date

      if handover.community_responsible? &&
        handover.reason == 'determinate_short' &&
        mpc_offender.ldu_email_address.present? &&
        mpc_offender.allocated_com_name.blank?

        last_chaser = db_offender.email_histories.where(event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION).last
        if last_chaser.nil? || last_chaser.created_at < 2.days.ago
          # create the history first so that the validations will help with hard failures due to coding errors
          # rather than waiting for the mailer to object
          db_offender.email_histories.create! prison: mpc_offender.prison_id,
                                              name: mpc_offender.ldu_name,
                                              email: mpc_offender.ldu_email_address,
                                              event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION

          CommunityMailer.with(
            email: mpc_offender.ldu_email_address,
            crn_number: mpc_offender.crn,
            prison_name: PrisonService.name_for(mpc_offender.prison_id),
            prisoner_name: "#{mpc_offender.first_name} #{mpc_offender.last_name}",
            prisoner_number: mpc_offender.nomis_offender_id
          ).assign_com_less_than_10_months.deliver_later
        end
      end
    end
  end
end
