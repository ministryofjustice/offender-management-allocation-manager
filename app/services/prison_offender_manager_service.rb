class PrisonOffenderManagerService
  def self.get_pom_detail(nomis_staff_id)
    PomDetail.find_or_create_by!(nomis_staff_id: nomis_staff_id.to_i) { |s|
      s.working_pattern = s.working_pattern || 0.0
      s.status = s.status || 'inactive'
    }
  end

  def self.get_poms(prison)
    poms = Nomis::Elite2::Api.prisoner_offender_manager_list(prison)
    poms.map { |pom|
      detail = get_pom_detail(pom.staff_id)
      pom.add_detail(detail)
      pom
    }
  end

  def self.get_pom_names(prison)
    poms_list = PrisonOffenderManagerService.get_poms(prison)
    poms_list.each_with_object({}) { |p, hsh|
      hsh[p.staff_id] = p.full_name
    }
  end

  def self.get_allocations_for_pom(nomis_staff_id)
    detail = PrisonOffenderManagerService.get_pom_detail(nomis_staff_id)
    detail.allocations.where(active: true)
  end

  def self.get_allocated_offenders(nomis_staff_id)
    allocation_list = PrisonOffenderManagerService.get_allocations_for_pom(nomis_staff_id)

    offender_ids = allocation_list.map(&:nomis_offender_id)
    offender_map = OffenderService.get_sentence_details(offender_ids)

    allocations_and_offender = []
    allocation_list.each do |alloc|
      allocations_and_offender << [alloc, offender_map[alloc.nomis_offender_id]]
    end
    allocations_and_offender
  end

  def self.get_new_allocations(nomis_staff_id)
    allocations = PrisonOffenderManagerService.get_allocated_offenders(nomis_staff_id)
    allocations.select { |allocation, _offender| allocation.created_at >= 7.days.ago }
  end

  def self.get_signed_in_pom_details(current_user)
    user = Nomis::Elite2::Api.fetch_nomis_user_details(current_user)
    poms_list = PrisonOffenderManagerService.get_poms(user.active_case_load_id)
    @pom = poms_list.select { |p| p.staff_id.to_i == user.staff_id.to_i }.first
  end
end
