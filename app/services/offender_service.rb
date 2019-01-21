class OffenderService
  def get_offender(noms_id)
    Nomis::Custody::Api.get_offender(noms_id)
  end

  def get_offenders_for_prison(prison, page_number: 0)
    offenders = Nomis::Elite2::Api.get_offender_list(prison, page_number)

    tier_map = Ndelius::Api.get_records(
      offenders.data.map(&:offender_no)
    )

    offenders.data.each do |offender|
      record = tier_map[offender.offender_no]
      offender.tier = record.tier if record
    end

    offenders
  end
end
