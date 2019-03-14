module SearchHelper
  # rubocop:disable Metrics/MethodLength
  def cta_for_offender(offender)
    offender_id = offender.offender_no

    if offender.tier.blank?
      return link_to(
        'Edit',
        new_case_information_path(nomis_offender_id: offender_id)
      )
    end

    if offender.allocated_pom_name.blank?
      return link_to(
        'Allocate',
        new_allocations_path(nomis_offender_id: offender_id)
      )
    end

    link_to('Reallocate', new_allocations_path(nomis_offender_id: offender_id))
  end
  # rubocop:enable Metrics/MethodLength
end
