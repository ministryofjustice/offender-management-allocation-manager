# frozen_string_literal: true

class AllocationService
  def self.allocate_secondary(
    nomis_offender_id:,
    secondary_pom_nomis_id:,
    created_by_username:,
    message:
  )
    alloc_version = AllocationHistory.find_by!(
      nomis_offender_id: nomis_offender_id
    )

    coworking_pom = HmppsApi::NomisUserRolesApi.staff_details(secondary_pom_nomis_id)

    created_by_user = HmppsApi::PrisonApi::UserApi.user_details(created_by_username)

    alloc_version.update!(
      secondary_pom_name: "#{coworking_pom.last_name}, #{coworking_pom.first_name}",
      created_by_name: "#{created_by_user.first_name} #{created_by_user.last_name}",
      secondary_pom_nomis_id: secondary_pom_nomis_id,
      event: AllocationHistory::ALLOCATE_SECONDARY_POM,
      event_trigger: AllocationHistory::USER
    )

    EmailService.send_coworking_primary_email(allocation: alloc_version, message: message)

    EmailService.send_secondary_email(allocation: alloc_version, message: message,
                                      pom_nomis_id: secondary_pom_nomis_id, pom_firstname: coworking_pom.first_name)
  end

  def self.create_or_update(params, further_info = {})
    primary_pom = HmppsApi::NomisUserRolesApi.staff_details(params[:primary_pom_nomis_id])
    created_by_user = HmppsApi::PrisonApi::UserApi.user_details(params[:created_by_username])

    params_copy = params.except(:created_by_username).merge(
      primary_pom_name: "#{primary_pom.last_name}, #{primary_pom.first_name}",
      created_by_name: "#{created_by_user.first_name} #{created_by_user.last_name}",
      primary_pom_allocated_at: Time.zone.now.utc
    )

    # When we look up the current allocation, we only do this for the current
    # offender, and NOT for the current prison. The offender may have been
    # transferred here and their allocation record may have a nil prison.
    alloc_version = AllocationHistory.find_by(
      nomis_offender_id: params_copy[:nomis_offender_id]
    )

    if alloc_version.nil?
      alloc_version = AllocationHistory.create!(params_copy)
    else
      alloc_version.update!(params_copy)
    end

    EmailService.send_email(allocation: alloc_version,
                            message: params[:message],
                            pom_nomis_id: params[:primary_pom_nomis_id],
                            further_info: further_info)

    alloc_version
  end

  def self.allocation_history_pom_emails(allocation)
    history = allocation.get_old_versions.append(allocation)
    pom_ids = history.map { |h| [h.primary_pom_nomis_id, h.secondary_pom_nomis_id] }.flatten.compact.uniq

    pom_ids.index_with { |pom_id| HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(pom_id).first }
  end

  # Gets the versions in *forward* order - so often we want to reverse
  # this list as we're interested in recent rather than ancient history
  # Returns an array of CaseHistory objects
  def self.history(allocation)
    return [] if allocation.blank?

    version_pairs = allocation.get_old_versions.append(allocation).zip(allocation.versions)

    # make CaseHistory records which contain the previous and current allocation history
    # records - so that deallocation can look at the old version to work out the POM name and ID
    [CaseHistory.new(nil, version_pairs.first.first, version_pairs.first.second)] +
      version_pairs.each_cons(2).map do |prev_pair, curr_pair|
        CaseHistory.new(prev_pair.first, curr_pair.first, curr_pair.second)
      end
  end

  def self.pom_terms(allocation)
    allowed_events = %w[allocate_primary_pom reallocate_primary_pom]

    [].tap do |terms|
      history(allocation).select { |h| allowed_events.include?(h.event) }.sort_by(&:created_at).each do |hist|
        next if terms.any? && hist.primary_pom_name == terms.last[:name]

        terms.last[:ended_at] = hist.created_at if terms.any?
        terms << { name: hist.primary_pom_name, started_at: hist.created_at, ended_at: nil, email: hist.primary_pom_email }
      end
    end
  end
end
