class OffenderService
  def get_offender(noms_id)
    Nomis::Custody::Api.get_offender(noms_id)
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
