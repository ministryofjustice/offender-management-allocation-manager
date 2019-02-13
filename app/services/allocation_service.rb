class AllocationService
  # rubocop:disable Metrics/MethodLength
  def self.create_allocation(params)
    Allocation.transaction do
      Allocation.where(nomis_offender_id: params[:nomis_offender_id]).
        update_all(active: false)

      params[:pom_detail_id] = PrisonOffenderManagerService.
        get_pom_detail(params[:nomis_staff_id]).id

      Allocation.create!(params) do |alloc|
        alloc.active = true
        alloc.save!
      end
    end
    delete_overrides(params)
  end
  # rubocop:enable Metrics/MethodLength

  def self.active_allocations(nomis_offender_ids)
    Allocation.where(nomis_offender_id: nomis_offender_ids, active: true).map { |a|
      [
        a[:nomis_offender_id],
        a
      ]
    }.to_h
  end

  def self.create_override(params)
    o = Override.find_or_create_by(
      nomis_staff_id: params[:nomis_staff_id],
      nomis_offender_id: params[:nomis_offender_id]
    )
    o.override_reasons = params[:override_reasons]
    o.more_detail = params[:more_detail]
    o.save!
    o
  end

private

  def self.delete_overrides(params)
    Override.where(
      nomis_staff_id: params[:nomis_staff_id],
      nomis_offender_id: params[:nomis_offender_id]).
        destroy_all
  end
end
