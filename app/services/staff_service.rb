class StaffService
  def self.get_prisoner_offender_managers(prison)
    poms = Nomis::Elite2::Api.prisoner_offender_manager_list(prison)
    staff_ids = poms.data.map(&:staff_id)

    PrisonOffenderManagerService.get_poms(staff_ids)
  end
end
