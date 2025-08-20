# frozen_string_literal: true

class NomisUserRolesService
  # @param [Prison] prison
  # @param [String] filter
  def self.search_staff(prison, filter)
    response = HmppsApi::NomisUserRolesApi.get_users(
      caseload: prison.code, filter: filter
    )

    results = response.fetch('content', [])
    total_elements = response.fetch('totalElements', 0)

    # We remove already onboarded POMs from the search results
    existing_pom_ids = prison.pom_details.pluck(:nomis_staff_id)
    filtered_results = results.reject { |result| existing_pom_ids.include?(result['staffId']) }
    total_elements -= (results.size - filtered_results.size)

    [filtered_results, total_elements]
  end

  # @param [Prison] prison
  # @param [Integer] nomis_staff_id
  # @param [Hash] config
  def self.add_pom(prison, nomis_staff_id, config)
    HmppsApi::NomisUserRolesApi.set_staff_role(
      prison.code, nomis_staff_id, config
    )

    # This should not be neccessary if we decide to use NOMIS working hours
    # upon reading the list of POMS.
    # For now, we are not doing that so we need to create the PomDetail here
    # as part of the onboarding to save the correct hours.
    prison.pom_details.create!(
      nomis_staff_id:, status: 'active', hours_per_week: config[:hours_per_week]
    )
  end

  # @param [Prison] prison
  # @param [Integer] nomis_staff_id
  def self.remove_pom(prison, nomis_staff_id)
    AllocationHistory.deallocate_primary_pom(nomis_staff_id, prison.code)
    AllocationHistory.deallocate_secondary_pom(nomis_staff_id, prison.code)

    prison.pom_details.destroy_by(nomis_staff_id:)

    pom = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(
      prison.code, staff_id: nomis_staff_id
    ).first

    # We attempt to also expire their POM role, but it may no longer exist
    HmppsApi::NomisUserRolesApi.expire_staff_role(pom) if pom
  end
end
