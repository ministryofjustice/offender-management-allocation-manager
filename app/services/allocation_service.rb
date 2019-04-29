# frozen_string_literal: true

class AllocationService
  # rubocop:disable Metrics/MethodLength
  def self.create_allocation(params)
    set_names = proc { |alloc|
      pom_firstname, pom_secondname =
        PrisonOffenderManagerService.get_pom_name(params[:primary_pom_nomis_id])
      user_firstname, user_secondname =
        PrisonOffenderManagerService.get_user_name(params[:created_by_username])

      alloc.primary_pom_name = "#{pom_firstname} #{pom_secondname}"
      alloc.created_by_name = "#{user_firstname} #{user_secondname}"
    }

    allocation = Allocation.transaction {
      Allocation.where(nomis_offender_id: params[:nomis_offender_id]).
        update_all(active: false)

      Allocation.create!(params) do |alloc|
        set_names.call(alloc)
        alloc.active = params.fetch(:active, true)
        alloc.save!
      end
    }

    params[:pom_detail_id] = PrisonOffenderManagerService.
      get_pom_detail(params[:primary_pom_nomis_id]).id

    EmailService.instance(params).send_allocation_email
    delete_overrides(params)

    allocation
  end
  # rubocop:enable Metrics/MethodLength

  def self.active_allocation?(nomis_offender_id)
    Allocation.where(nomis_offender_id: nomis_offender_id, active: true).count > 0
  end

  def self.active_allocations(nomis_offender_ids)
    Allocation.where(nomis_offender_id: nomis_offender_ids, active: true).map { |a|
      [
        a[:nomis_offender_id],
        a
      ]
    }.to_h
  end

  def self.previously_allocated_poms(nomis_offender_id)
    Allocation.where(
      nomis_offender_id: nomis_offender_id, active: false
    ).map(&:primary_pom_nomis_id)
  end

  def self.offender_allocation_history(nomis_offender_id)
    allocations = Allocation.
      where(nomis_offender_id: nomis_offender_id).
      order('created_at DESC')

    AllocationList.new(allocations)
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

  def self.deallocate_primary_pom(nomis_staff_id)
    Allocation.where(primary_pom_nomis_id: nomis_staff_id).update_all(active: false)
  end

  def self.deallocate_offender(nomis_offender_id)
    Allocation.where(nomis_offender_id: nomis_offender_id).update_all(active: false)
  end

  def self.last_allocation(nomis_offender_id)
    Allocation.where(
      nomis_offender_id: nomis_offender_id,
      active: false
    ).last
  end

  def self.active_allocations_with_pom_detail(nomis_offender_ids)
    Allocation.where(
      nomis_offender_id: nomis_offender_ids, active: true
    ).preload(:pom_detail)
  end

  def self.primary_pom_nomis_id(nomis_offender_id)
    Allocation.active_allocations(nomis_offender_id).first.primary_pom_nomis_id
  end

private

  def self.delete_overrides(params)
    Override.where(
      nomis_staff_id: params[:primary_pom_nomis_id],
      nomis_offender_id: params[:nomis_offender_id]).
        destroy_all
  end
end
