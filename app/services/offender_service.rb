class OffenderService
  def get_offender(offender_no)
    Nomis::Elite2::Api.get_offender(offender_no).tap { |o|
      o.data.tier = Ndelius::Api.get_record(offender_no).tier

      release = Nomis::Elite2::Api.get_bulk_release_dates([offender_no])
      o.data.release_date = release.data[offender_no]

      o.data.main_offence = Nomis::Elite2::Api.get_offence(o.data.latest_booking_id).data
    }
  end

  def get_offenders_for_prison(prison, page_number: 0)
    offenders = Nomis::Elite2::Api.get_offender_list(prison, page_number)
    offender_ids = offenders.data.map(&:offender_no)

    tier_map = Ndelius::Api.get_records(offender_ids)
    release_dates = Nomis::Elite2::Api.get_bulk_release_dates(offender_ids)

    offenders.data.each do |offender|
      record = tier_map[offender.offender_no]
      offender.tier = record.tier if record
      offender.release_date = release_dates.data[offender.offender_no]
    end

    offenders
  end
end
