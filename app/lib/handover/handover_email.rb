class Handover::HandoverEmail
  def self.deliver_if_deliverable(handover_email_type, nomis_offender_id, deliver_now: false, **mailer_args)
    if OffenderEmailOptOut.find_by(offender_email_type: handover_email_type,
                                   nomis_offender_id: nomis_offender_id).present? ||
      OffenderEmailSent.find_by(offender_email_type: handover_email_type,
                                nomis_offender_id: nomis_offender_id).present?
      return
    end

    mailer = HandoverMailer.public_send(handover_email_type, **mailer_args.merge(nomis_offender_id: nomis_offender_id))

    ApplicationRecord.transaction do
      OffenderEmailSent.create! offender_email_type: handover_email_type, nomis_offender_id: nomis_offender_id
      deliver_now ? mailer.deliver_now : mailer.deliver_later
    end
  end
end