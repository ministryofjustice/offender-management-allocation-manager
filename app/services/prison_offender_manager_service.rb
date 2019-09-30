# frozen_string_literal: true

class PrisonOffenderManagerService
  # Note - get_poms and get_pom return different data...
  def self.get_poms(prison)
    poms = Nomis::Elite2::PrisonOffenderManagerApi.list(prison)
    pom_details = PomDetail.where(nomis_staff_id: poms.map(&:staff_id).map(&:to_i))

    poms = poms.map { |pom|
      detail = get_pom_detail(pom_details, pom.staff_id.to_i)
      pom.add_detail(detail, prison)
      pom
    }.compact

    poms
  end

  def self.get_pom(caseload, nomis_staff_id)
    poms_list = get_poms(caseload)
    if poms_list.blank?
      log_missing_pom(caseload, nomis_staff_id)
      return nil
    end

    pom = poms_list.select { |p| p.staff_id == nomis_staff_id.to_i }.first
    if pom.blank?
      log_missing_pom(caseload, nomis_staff_id)
      return nil
    end

    pom.emails = get_pom_emails(pom.staff_id)
    pom
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
    user = Nomis::Elite2::UserApi.user_details(username)
    [user.first_name, user.last_name]
  end

  # rubocop:disable Metrics/MethodLength
  def self.get_allocated_offenders(nomis_staff_id, prison)
    allocation_list = AllocationVersion.active_pom_allocations(
      nomis_staff_id,
      prison
    )

    offender_ids = allocation_list.map(&:nomis_offender_id)
    booking_ids = allocation_list.map(&:nomis_booking_id)

    # Get an offender map of offender_id to sentence details and a hash of
    # offender_no to case_info_details so we can fill in a fake offender
    # object for each allocation. This will allow us to calculate the
    # pom responsibility without having to make an API request per-offender.
    offender_map = OffenderService.get_sentence_details(booking_ids)
    case_info = CaseInformationService.get_case_info_for_offenders(offender_ids)

    allocation_list.map do |alloc|
      offender_stub = Nomis::Offender.new
      offender_stub.sentence = offender_map[alloc.nomis_booking_id]

      record = case_info[alloc.nomis_offender_id]
      if record.present?
        offender_stub.tier = record.tier
        offender_stub.case_allocation = record.case_allocation
        offender_stub.welsh_offender = record.welsh_offender
      end

      if alloc.for_primary_only?
        responsibility =
          ResponsibilityService.calculate_pom_responsibility(offender_stub).to_s
      else
        responsibility = ResponsibilityService::COWORKING
      end
      AllocationWithSentence.new(
        nomis_staff_id,
        alloc,
        offender_map[alloc.nomis_booking_id],
        responsibility
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.unavailable_pom_count(prison)
    poms = PrisonOffenderManagerService.get_poms(prison).reject { |pom|
      pom.status == 'active'
    }
    poms.count
  end

  def self.get_signed_in_pom_details(current_user, prison)
    user = Nomis::Elite2::UserApi.user_details(current_user)

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

private

  def self.get_pom_detail(pom_details, nomis_staff_id)
    pom_details.detect { |pd| pd.nomis_staff_id == nomis_staff_id } ||
      PomDetail.create!(nomis_staff_id: nomis_staff_id,
                        working_pattern: 0.0,
                        status: 'active')
  end

  def self.log_missing_pom(caseload, nomis_staff_id)
    Rails.logger.warn("POM #{nomis_staff_id} does not work at prison #{caseload}")
  end
end
