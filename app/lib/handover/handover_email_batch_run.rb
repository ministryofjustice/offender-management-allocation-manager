class Handover::HandoverEmailBatchRun
  class << self
    def send_one_upcoming_handover_window(offender, deliver_now: false, for_date: Time.zone.now.to_date)
      chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
      return unless chd&.handover_date && chd.handover_date == for_date + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION

      handover_case = Handover::HandoverCase.new(offender, chd)
      Handover::HandoverEmail.deliver_if_deliverable(
        :upcoming_handover_window,
        offender.offender_no,
        offender.staff_member.staff_id,
        email: offender.staff_member.email_address,
        full_name_ordered: offender.full_name_ordered,
        first_name: offender.first_name.titleize,
        handover_date: format_date(chd.handover_date),
        enhanced_handover: offender.enhanced_handover?,
        release_date: format_date(handover_case.earliest_release_for_handover&.date),
        deliver_now: deliver_now,
      )
      Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=upcoming_handover_window,for_date=#{for_date.iso8601}")
    end

    def send_one_handover_date(offender, deliver_now: false, for_date: Time.zone.now.to_date)
      chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
      return unless chd&.handover_date && chd.handover_date == for_date && offender.has_com?

      handover_case = Handover::HandoverCase.new(offender, chd)
      Handover::HandoverEmail.deliver_if_deliverable(
        :handover_date,
        offender.offender_no,
        offender.staff_member.staff_id,
        email: offender.staff_member.email_address,
        full_name_ordered: offender.full_name_ordered,
        first_name: offender.first_name.titleize,
        release_date: format_date(handover_case.earliest_release_for_handover&.date),
        com_name: offender.allocated_com_name,
        com_email: offender.allocated_com_email,
        enhanced_handover: offender.enhanced_handover?,
        deliver_now: deliver_now,
      )
      Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=handover_date,for_date=#{for_date.iso8601}")
    end

    def send_one_com_allocation_overdue(offender, deliver_now: false, for_date: Time.zone.now.to_date)
      chd = CalculatedHandoverDate.find_by(nomis_offender_id: offender.offender_no)
      return unless chd&.handover_date && chd.handover_date == for_date - 14.days && !offender.has_com?

      handover_case = Handover::HandoverCase.new(offender, chd)
      Handover::HandoverEmail.deliver_if_deliverable(
        :com_allocation_overdue,
        offender.offender_no,
        offender.staff_member.staff_id,
        email: offender.staff_member.email_address,
        full_name_ordered: offender.full_name_ordered,
        handover_date: format_date(chd.handover_date),
        release_date: format_date(handover_case.earliest_release_for_handover&.date),
        ldu_name: offender.ldu_name,
        ldu_email: offender.ldu_email_address,
        enhanced_handover: offender.enhanced_handover?,
        deliver_now: deliver_now,
      )
      Rails.logger.info("event=handover_email_delivered,nomis_offender_id=#{offender.offender_no},email=com_allocation_overdue,for_date=#{for_date.iso8601}")
    end

    def send_all(for_date: Time.zone.now.to_date)
      Rails.logger.info("event=handover_email_batch_run_start,for_date=#{for_date.iso8601}")
      AllocatedOffender.all.find_each do |offender|
        with_error_handling(offender.offender_no, 'upcoming_handover_window') do
          send_one_upcoming_handover_window(offender, for_date: for_date)
        end

        with_error_handling(offender.offender_no, 'handover_date') do
          send_one_handover_date(offender, for_date: for_date)
        end

        with_error_handling(offender.offender_no, 'com_allocation_overdue') do
          send_one_com_allocation_overdue(offender, for_date: for_date)
        end
      end
    ensure
      Rails.logger.info("event=handover_email_batch_run_end,for_date=#{for_date.iso8601}")
    end

  private

    def format_date(date)
      date.strftime('%-d %B %Y')
    end

    def with_error_handling(nomis_offender_id, email_type)
      yield
    rescue StandardError => e
      raise unless Rails.env.production?

      Rails.logger.error("event=handover_email_batch_run_error,email=#{email_type},nomis_offender_id=#{nomis_offender_id}|#{e.inspect},#{e.backtrace.join(',')}")
    end
  end
end
