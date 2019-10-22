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

  def self.get_pom(prison_id, nomis_staff_id)
    raise ArgumentError, 'PrisonOffenderManagerService#get_pom(nil)' if nomis_staff_id.nil?

    poms_list = get_poms(prison_id)
    if poms_list.blank?
      log_missing_pom(prison_id, nomis_staff_id)
      return nil
    end

    pom = poms_list.find { |p| p.staff_id == nomis_staff_id.to_i }
    if pom.blank?
      log_missing_pom(prison_id, nomis_staff_id)
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
    # Get all the allocations for the POM at this prison
    allocation_list = AllocationVersion.active_pom_allocations(
      nomis_staff_id,
      prison
    )

    offender_ids = allocation_list.map(&:nomis_offender_id)

    # Get all of the offenders at this prison and select only those that
    # appear in an allocation.  Then for each one apply a map to determine
    # the responsibility and pair it with the allocation and sentence.
    OffenderService.get_offenders_for_prison(prison).select{ |offender|
      offender_ids.include?(offender.offender_no)
    }.map { |offender|
      # This is potentially slow, possibly of the order O(NM)
      allocation = allocation_list.detect { |alloc|
        alloc.nomis_offender_id == offender.offender_no
      }

      # If this is the primary POM, work out responsibility
      if allocation.primary_pom_nomis_id == nomis_staff_id
        responsibility =
          ResponsibilityService.calculate_pom_responsibility(offender).to_s
      else
        responsibility = ResponsibilityService::COWORKING
      end

      AllocationWithSentence.new(
        nomis_staff_id,
        allocation,
        offender.sentence,
        responsibility
      )
    }
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
    poms_list.find { |p| p.staff_id.to_i == user.staff_id.to_i }
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
        PomDetail.find_or_create_by!(nomis_staff_id: nomis_staff_id) do |pom|
          pom.working_pattern = 0.0
          pom.status = 'active'
        end
  end

  def self.log_missing_pom(caseload, nomis_staff_id)
    Rails.logger.warn("POM #{nomis_staff_id} does not work at prison #{caseload}")
  end
end
