# frozen_string_literal: true

class PrisonOffenderManagerService
  def self.get_pom_detail(nomis_staff_id)
    PomDetail.find_or_create_by!(nomis_staff_id: nomis_staff_id.to_i) { |s|
      s.working_pattern = s.working_pattern || 0.0
      s.status = s.status || 'active'
    }
  end

  # Note - get_poms and get_pom return different data...
  def self.get_poms(prison)
    poms = Nomis::Elite2::PrisonOffenderManagerApi.list(prison)

    poms = poms.map { |pom|
      detail = get_pom_detail(pom.staff_id)
      pom.add_detail(detail, prison)
      pom
    }.compact

    poms
  end

  def self.get_pom(caseload, nomis_staff_id)
    poms_list = get_poms(caseload)
    return nil if poms_list.blank?

    @pom = poms_list.select { |p| p.staff_id == nomis_staff_id.to_i }.first
    return nil if @pom.blank?

    @pom.emails = get_pom_emails(@pom.staff_id)
    @pom
  end

  def self.get_pom_emails(nomis_staff_id)
    Nomis::Elite2::PrisonOffenderManagerApi.fetch_email_addresses(nomis_staff_id)
  end

  def self.get_pom_names(prison)
    poms_list = get_poms(prison)
    poms_list.each_with_object({}) { |p, hsh|
      hsh[p.staff_id] = p.full_name
    }
  end

  def self.get_pom_name(nomis_staff_id)
    staff = Nomis::Elite2::PrisonOffenderManagerApi.staff_detail(nomis_staff_id)
    [staff.first_name, staff.last_name]
  end

  def self.get_user_name(username)
    user = Nomis::Custody::UserApi.user_details(username)
    [user.first_name, user.last_name]
  end

  def self.get_allocations_for_primary_pom(nomis_staff_id, prison)
    AllocationVersion.active_primary_pom_allocations(nomis_staff_id, prison)
  end

  def self.get_allocated_offenders(nomis_staff_id, prison)
    allocation_list = get_allocations_for_primary_pom(nomis_staff_id, prison)

    offender_ids = allocation_list.map(&:nomis_offender_id)
    booking_ids = allocation_list.map(&:nomis_booking_id)

    # Get an offender map of offender_id to sentence details and a hash of
    # offender_no to case info details so we can fill in a fake offender
    # object for each allocation. This will allow us to calculate the
    # pom responsibility without having to make an API request per-offender.
    offender_map = OffenderService.get_sentence_details(booking_ids)
    case_info = CaseInformationService.get_case_info_for_offenders(offender_ids)

    allocation_list.each do |alloc|
      offender_stub = Nomis::Models::Offender.new
      offender_stub.sentence = offender_map[alloc.nomis_booking_id]

      record = case_info[alloc.nomis_offender_id]
      if record.present?
        offender_stub.tier = record.tier
        offender_stub.case_allocation = record.case_allocation
        offender_stub.omicable = record.omicable
      end

      alloc.responsibility =
        ResponsibilityService.new.calculate_pom_responsibility(offender_stub)
    end

    allocation_list.map do |alloc|
      AllocationWithSentence.new(alloc, offender_map[alloc.nomis_booking_id])
    end
  end

  def self.unavailable_pom_count(prison)
    poms = PrisonOffenderManagerService.get_poms(prison).reject { |pom|
      pom.status == 'active'
    }
    poms.count
  end

  def self.get_signed_in_pom_details(current_user, prison)
    user = Nomis::Custody::UserApi.user_details(current_user)

    poms_list = get_poms(prison)
    poms_list.select { |p| p.staff_id.to_i == user.staff_id.to_i }.first
  end

  def self.update_pom(params)
    pom = PomDetail.by_nomis_staff_id(params[:nomis_staff_id])
    pom.working_pattern = params[:working_pattern]
    pom.status = params[:status] || pom.status
    pom.save

    if pom.valid? && pom.status == 'inactive'
      AllocationVersion.deallocate_primary_pom(params[:nomis_staff_id])
    end

    pom
  end
end
