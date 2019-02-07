class AllocationService
  def self.create_allocation(params)
    Allocation.transaction do
      Allocation.where(nomis_offender_id: params[:nomis_offender_id]).
        update_all(active: false)

      params[:prison_offender_manager] = PrisonOffenderManagerService.
        get_prison_offender_manager(params[:nomis_staff_id])

      Allocation.create!(params) { |alloc|
        alloc.active = true
        alloc.save!
      }
    end
  end

  def self.active_allocations(nomis_offender_ids)
    Allocation.where(nomis_offender_id: nomis_offender_ids, active: true).map { |a|
      [
        a[:nomis_offender_id],
        a
      ]
    }.to_h
  end
end
