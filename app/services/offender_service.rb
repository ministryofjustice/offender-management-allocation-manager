class OffenderService
  def get_offender(noms_id)
    Nomis::Custody::Api.get_offender(noms_id)
  end

  def get_offenders_for_prison(prison, page_number: 0)
    Nomis::Elite2::Api.get_offender_list(prison, page_number)
  end
end
