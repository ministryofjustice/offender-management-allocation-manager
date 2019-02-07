class PrisonOffenderManagerService
  def self.get_pom_detail(nomis_staff_id)
    PomDetail.find_or_create_by!(nomis_staff_id: nomis_staff_id) { |s|
      s.working_pattern = s.working_pattern || 0.0
      s.status = s.status || 'inactive'
    }
  end

  def self.get_poms(prison)
    poms = Nomis::Elite2::Api.prisoner_offender_manager_list(prison)
    poms.data.map { |pom|
      detail = get_pom_detail(pom.staff_id)
      pom.add_detail(detail)
      pom
    }
  end
end
