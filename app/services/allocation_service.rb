# frozen_string_literal: true

class AllocationService
  # rubocop:disable Metrics/MethodLength
  def self.create_or_update(params)
    pom_firstname, pom_secondname =
      PrisonOffenderManagerService.get_pom_name(params[:primary_pom_nomis_id])
    user_firstname, user_secondname =
      PrisonOffenderManagerService.get_user_name(params[:created_by_username])

    params_copy = params.merge(
      primary_pom_name: "#{pom_firstname} #{pom_secondname}",
      created_by_name: "#{user_firstname} #{user_secondname}",
      primary_pom_allocated_at: DateTime.now.utc
    )

    alloc_version = AllocationVersion.find_by(
      nomis_offender_id: params_copy[:nomis_offender_id]
    )

    if alloc_version.nil?
      if AllocationVersion.where(prison: params_copy[:prison]).empty?
        PomMailer.new_prison_allocation_email(params_copy[:prison]).deliver_later
      end

      alloc_version = AllocationVersion.create!(params_copy)
    else
      alloc_version.update!(params_copy)
    end

    EmailService.instance(allocation: alloc_version, message: params[:message]).send_email

    delete_overrides(params_copy[:primary_pom_nomis_id], params_copy[:nomis_offender_id])

    alloc_version
  end
  # rubocop:enable Metrics/MethodLength

  def self.all_allocations
    AllocationVersion.all.map { |a|
      [
        a[:nomis_offender_id],
        a
      ]
    }.to_h
  end

  def self.allocations(nomis_offender_ids, prison)
    AllocationVersion.where(
      nomis_offender_id: nomis_offender_ids,
      prison: prison).
      map { |a|
      [
        a[:nomis_offender_id],
        a
      ]
    }.to_h
  end

  def self.previously_allocated_poms(nomis_offender_id)
    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

    return [] if allocation.nil?

    get_versions_for(allocation).
      map(&:primary_pom_nomis_id)
  end

  def self.offender_allocation_history(nomis_offender_id)
    current_allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

    unless current_allocation.nil?
      allocations = get_versions_for(current_allocation).
          append(current_allocation).
          sort_by!(&:updated_at).
          reverse!
      AllocationList.new(allocations)
    end
  end

  def self.allocation_history_pom_emails(history)
    pom_ids = history.map(&:primary_pom_nomis_id).uniq.compact
    pom_emails = {}

    pom_ids.each do |pom_id|
      pom_emails[pom_id] = PrisonOffenderManagerService.get_pom_emails(pom_id).first
    end

    pom_emails
  end

  def self.create_override(params)
    Override.find_or_create_by(
      nomis_staff_id: params[:nomis_staff_id],
      nomis_offender_id: params[:nomis_offender_id]
    ).tap { |o|
      o.override_reasons = params[:override_reasons]
      o.suitability_detail = params[:suitability_detail]
      o.more_detail = params[:more_detail]
      o.save
    }
  end

  def self.current_allocation_for(nomis_offender_id)
    AllocationVersion.allocations(nomis_offender_id).last
  end

private

  def self.get_versions_for(allocation)
    allocation.versions.map { |version|
      # 'create' events do not have '#reify' method
      version.reify unless version.event == 'create'
    }.compact
  end

  def self.delete_overrides(nomis_staff_id, nomis_offender_id)
    Override.where(
      nomis_staff_id: nomis_staff_id,
      nomis_offender_id: nomis_offender_id).
    destroy_all
  end
end
