# frozen_string_literal: true

module SearchHelper
  # rubocop:disable Metrics/MethodLength
  def cta_for_offender(prison, offender)
    offender_id = offender.offender_no

    auto_delius_import_enabled = Flipflop.auto_delius_import? ||
        (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').include?(prison)

    if offender.tier.blank?
      if auto_delius_import_enabled
        return link_to(
          'Update',
          prison_case_information_path(prison, nomis_offender_id: offender_id)
        )
      else
        return link_to(
          'Edit',
          new_prison_case_information_path(prison, nomis_offender_id: offender_id)
        )
      end
    end

    if offender.allocated_pom_name.blank?
      return link_to(
        'Allocate',
        new_prison_allocation_path(prison, nomis_offender_id: offender_id)
      )
    end

    link_to(
      'View',
      prison_allocation_path(prison, nomis_offender_id: offender_id)
    )
  end
  # rubocop:enable Metrics/MethodLength
end
