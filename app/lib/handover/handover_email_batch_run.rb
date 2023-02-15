class Handover::HandoverEmailBatchRun
  def self.send_all_upcoming_handover_window(for_date: Time.zone.now.to_date)
    Rails.logger.info("event=start_handover_email_batch_run,email=upcoming_handover_window,for_date=#{for_date.iso8601}")
    AllocatedOffender.all.each do |offender|
      send_one_upcoming_handover_window(offender, for_date: for_date)
    end
  end

  def self.send_one_upcoming_handover_window(offender, deliver_now: false, for_date: Time.zone.now.to_date)
    chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
    return unless chd.handover_date == for_date + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION

    Handover::HandoverEmail.deliver_if_deliverable(
      :upcoming_handover_window,
      offender.offender_no,
      offender.staff_member.staff_id,
      email: offender.staff_member.email_address,
      full_name_ordered: offender.full_name_ordered,
      first_name: offender.first_name,
      handover_date: format_date(chd.handover_date),
      service_provider: offender.case_allocation,
      release_date: format_date(offender.earliest_release_date),
      deliver_now: deliver_now,
    )
    Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=upcoming_handover_window,for_date=#{for_date.iso8601}")
  end

  def self.send_all_handover_date(for_date: Time.zone.now.to_date)
    Rails.logger.info("event=start_handover_email_batch_run,email=handover_date,for_date=#{for_date.iso8601}")
    AllocatedOffender.all.each do |offender|
      send_one_handover_date(offender, for_date: for_date)
    end
  end

  def self.send_one_handover_date(offender, deliver_now: false, for_date: Time.zone.now.to_date)
    chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
    return unless chd.handover_date == for_date && offender.has_com?

    Handover::HandoverEmail.deliver_if_deliverable(
      :handover_date,
      offender.offender_no,
      offender.staff_member.staff_id,
      email: offender.staff_member.email_address,
      full_name_ordered: offender.full_name_ordered,
      first_name: offender.first_name,
      release_date: format_date(offender.earliest_release_date),
      com_name: offender.allocated_com_name,
      com_email: offender.allocated_com_email,
      service_provider: offender.case_allocation,
      deliver_now: deliver_now,
    )
    Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=handover_date,for_date=#{for_date.iso8601}")
  end

  def self.format_date(date)
    date.strftime('%-d %B %Y')
  end
end
