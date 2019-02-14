class OffenderService
  def get_offender(offender_no)
    Nomis::Elite2::Api.get_offender(offender_no).tap { |o|
      record = Ndelius::Api.get_record(offender_no)
      o.data.tier = record.tier
      o.data.case_allocation = record.case_allocation

      release = Nomis::Elite2::Api.get_bulk_release_dates([offender_no])
      o.data.release_date = release.data[offender_no]

      o.data.main_offence = Nomis::Elite2::Api.get_offence(o.data.latest_booking_id).data
    }
  end

  # rubocop:disable Metrics/MethodLength
  def get_offenders_for_prison(prison, page_number: 0, page_size: 10)
    offenders = Nomis::Elite2::Api.get_offender_list(
      prison,
      page_number,
      page_size: page_size
    )
    offender_ids = offenders.data.map(&:offender_no)

    tier_map = Ndelius::Api.get_records(offender_ids)
    release_dates = if offender_ids.count > 0
                      Nomis::Elite2::Api.get_bulk_release_dates(offender_ids)
                    else
                      {}
                    end

    offenders.data = offenders.data.select { |offender|
      record = tier_map[offender.offender_no]
      offender.tier = record.tier if record
      offender.release_date = release_dates.data[offender.offender_no]
      offender.release_date.present?
    }
    offenders
  end
  # rubocop:enable Metrics/MethodLength

  def self.get_sentence_details(offender_id_list)
    Nomis::Elite2::Api.get_bulk_sentence_details(offender_id_list).data
  end
end
