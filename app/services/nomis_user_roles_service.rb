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

    # We remove existing POMs from the search results
    existing_pom_ids = prison.get_list_of_poms(include_deleted: true).map(&:staff_id)
    filtered_results = results.reject { |result| existing_pom_ids.include?(result['staffId']) }
    total_elements -= (results.size - filtered_results.size)

    [filtered_results, total_elements]
  end

  # @param [Prison] prison
  # @param [Integer] nomis_staff_id
  # @param [String] created_by
  # @param [Hash] config
  def self.add_pom(prison, nomis_staff_id, created_by, config)
    HmppsApi::NomisUserRolesApi.set_staff_role(
      prison.code, nomis_staff_id, config
    )

    publish_audit_event(
      tags: %w[nomis_role created],
      prison_code: prison.code,
      staff_id: nomis_staff_id,
      data: {
        position: config[:position],
        schedule_type: config[:schedule_type],
        hours_per_week: config[:hours_per_week],
      }
    )

    # Expire cache, otherwise the POM just added might not come back in the
    # list endpoint until any previous cached request expires (which could take 1h)
    HmppsApi::PrisonApi::PrisonOffenderManagerApi.expire_list_cache(prison.code)

    # This should not be neccessary if we decide to use NOMIS working hours
    # upon reading the list of POMS.
    # For now, we are not doing that so we need to create the PomDetail here
    # as part of the onboarding to save the correct hours.
    prison.pom_details.find_or_initialize_by(nomis_staff_id:).tap do |pd|
      pd.update!(created_by:, status: 'active', hours_per_week: config[:hours_per_week])
    end
  end

  # @param [Prison] prison
  # @param [Integer] nomis_staff_id
  def self.remove_pom(prison, nomis_staff_id)
    AllocationHistory.deallocate_pom(
      nomis_staff_id, prison.code, event_trigger: AllocationHistory::INACTIVE_POM
    )

    prison.pom_details.find_by(nomis_staff_id:)&.deleted!

    expire_nomis_role!(prison, nomis_staff_id)

    true
  end

  def self.expire_nomis_role!(prison, nomis_staff_id)
    pom = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(
      prison.code, staff_id: nomis_staff_id
    ).first

    if pom
      HmppsApi::NomisUserRolesApi.expire_staff_role(pom)

      publish_audit_event(
        tags: %w[nomis_role expired],
        prison_code: prison.code,
        staff_id: nomis_staff_id,
        data: {
          from_date: pom.from_date,
          to_date: pom.to_date,
          position: pom.position,
          schedule_type: pom.schedule_type,
          hours_per_week: pom.hours_per_week,
        }
      )

      # Expire cache, otherwise the POM just removed might still come back in the
      # list endpoint until any previous cached request expires (which could take 1h)
      HmppsApi::PrisonApi::PrisonOffenderManagerApi.expire_list_cache(prison.code)
    end
  rescue StandardError => e
    Rails.logger.error(
      "event=nomis_role_removal_failed,prison_id=#{prison.code},staff_id=#{nomis_staff_id},from_date=#{pom&.from_date}|#{e.message}"
    )
    Rails.error.report(e, severity: :warning, source: 'nomis_role_removal', context: {
      prison_id: prison.code,
      staff_id: nomis_staff_id,
      from_date: pom&.from_date,
    })
  end
  private_class_method :expire_nomis_role!

  def self.publish_audit_event(tags:, prison_code:, staff_id:, data: {})
    AuditEvent.publish(
      tags:,
      system_event: PaperTrail.request.whodunnit.blank?,
      username: PaperTrail.request.whodunnit,
      data: { prison_code:, staff_id: }.merge(data)
    )
  end
  private_class_method :publish_audit_event
end
