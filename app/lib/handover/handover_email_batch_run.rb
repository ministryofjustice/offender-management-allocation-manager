class Handover::HandoverEmailBatchRun
  def self.send_all_upcoming_handover_window(for_date: Time.zone.now.to_date)
    Rails.logger.info("event=start_handover_email_batch_run,email=upcoming_handover_window,for_date=#{for_date.iso8601}")
    for_all_allocated_offenders('upcoming_handover_window') do |offender|
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
      first_name: offender.first_name.titleize,
      handover_date: format_date(chd.handover_date),
      service_provider: offender.case_allocation,
      release_date: format_date(offender.earliest_release_date),
      deliver_now: deliver_now,
    )
    Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=upcoming_handover_window,for_date=#{for_date.iso8601}")
  end

  def self.send_all_handover_date(for_date: Time.zone.now.to_date)
    Rails.logger.info("event=start_handover_email_batch_run,email=handover_date,for_date=#{for_date.iso8601}")
    for_all_allocated_offenders('handover_date') do |offender|
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
      first_name: offender.first_name.titleize,
      release_date: format_date(offender.earliest_release_date),
      com_name: offender.allocated_com_name,
      com_email: offender.allocated_com_email,
      service_provider: offender.case_allocation,
      deliver_now: deliver_now,
    )
    Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=handover_date,for_date=#{for_date.iso8601}")
  end

  def self.send_all_com_allocation_overdue(for_date: Time.zone.now.to_date)
    Rails.logger.info("event=start_handover_email_batch_run,email=com_allocation_overdue,for_date=#{for_date.iso8601}")

    for_all_allocated_offenders('com_allocation_overdue') do |offender|
      send_one_com_allocation_overdue(offender, for_date: for_date)
    end
  end

  def self.send_one_com_allocation_overdue(offender, deliver_now: false, for_date: Time.zone.now.to_date)
    chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
    return unless chd.handover_date == for_date - 14.days && !offender.has_com?

    Handover::HandoverEmail.deliver_if_deliverable(
      :com_allocation_overdue,
      offender.offender_no,
      offender.staff_member.staff_id,
      email: offender.staff_member.email_address,
      full_name_ordered: offender.full_name_ordered,
      handover_date: format_date(chd.handover_date),
      release_date: format_date(offender.earliest_release_date),
      ldu_name: offender.ldu_name,
      ldu_email: offender.ldu_email_address,
      deliver_now: deliver_now,
    )
    Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=com_allocation_overdue,for_date=#{for_date.iso8601}")
  end

  class << self
    def format_date(date)
      date.strftime('%-d %B %Y')
    end

    def for_all_allocated_offenders(email_type)
      AllocatedOffender.all.each do |offender|
        yield(offender)
      rescue StandardError => e
        raise unless Rails.env.production?

        Rails.logger.error("event=handover_email_batch_run_error,email=#{email_type},nomis_offender_id=#{offender.offender_no}|#{e.inspect},#{e.backtrace.join(',')}")
      end
    end
  end
end
