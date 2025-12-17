class PersistOmicEligibility
  def self.for_offenders_at(prison_code)
    api_args = { ignore_legal_status: true, fetch_complexities: false, fetch_categories: false, fetch_movements: false }
    offenders = HmppsApi::PrisonApi::OffenderApi.get_offenders_in_prison(prison_code, **api_args)

    offenders.each do |offender|
      OmicEligibility.find_or_initialize_by(nomis_offender_id: offender.offender_no)
        .update(eligible: offender.inside_omic_policy?)
    end
  end

  def self.cleanup_records_updated_before(time)
    OmicEligibility.where('updated_at < ?', time).delete_all
  end
end
