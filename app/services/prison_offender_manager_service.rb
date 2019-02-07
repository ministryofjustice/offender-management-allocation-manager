class PrisonOffenderManagerService
  def self.get_prison_offender_manager(nomis_staff_id)
    PrisonOffenderManager.find_or_create_by!(nomis_staff_id: nomis_staff_id) { |s|
      s.working_pattern = s.working_pattern || 0.0
      s.status = s.status || 'inactive'
    }
  end

  def self.get_poms(nomis_staff_ids)
    PrisonOffenderManager.includes(:allocations).where(nomis_staff_id: nomis_staff_ids)
  end
end
