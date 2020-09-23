# frozen_string_literal: true

class PrisonOffenderManagerService
  # Note - get_poms_for and get_pom_at return different data...
  def self.get_poms_for(prison)
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::Prison::PrisonOffenderManager.list(prison)
    pom_details = PomDetail.where(nomis_staff_id: poms.map(&:staff_id))
    offender_numbers = Prison.new(prison).offenders.map(&:offender_no)

    poms.map { |pom|
      detail = get_pom_detail(pom_details, pom.staff_id.to_i)

      allocations = Allocation.active_pom_allocations(detail.nomis_staff_id, prison).
        where(nomis_offender_id: offender_numbers).
        map(&:nomis_offender_id)
      allocation_counts = CaseInformation.where(nomis_offender_id: allocations).
        group_by(&:tier)

      pom.tier_a = allocation_counts.fetch('A', []).size
      pom.tier_b = allocation_counts.fetch('B', []).size
      pom.tier_c = allocation_counts.fetch('C', []).size
      pom.tier_d = allocation_counts.fetch('D', []).size
      pom.no_tier = allocation_counts.fetch('N/A', []).size
      pom.status = detail.status
      pom.working_pattern = detail.working_pattern

      pom
    }.select { |pom| pom.prison_officer? || pom.probation_officer? }.uniq(&:staff_id)
  end

  def self.get_pom_at(prison_id, nomis_staff_id)
    raise ArgumentError, 'PrisonOffenderManagerService#get_pom_at(nil)' if nomis_staff_id.nil?

    poms_list = get_poms_for(prison_id)
    pom = poms_list.find { |p| p.staff_id == nomis_staff_id.to_i }
    if pom.blank?
      log_missing_pom(prison_id, nomis_staff_id)
      pom_staff_ids = poms_list.map(&:staff_id)
      raise StandardError, "Failed to find POM ##{nomis_staff_id} at #{prison_id} - list is #{pom_staff_ids}"
    end

    pom.emails = get_pom_emails(pom.staff_id)
    pom
  end

  def self.get_pom_emails(nomis_staff_id)
    HmppsApi::Prison::PrisonOffenderManager.fetch_email_addresses(nomis_staff_id)
  end

  def self.get_pom_names(prison)
    poms_list = get_poms_for(prison)
    poms_list.each_with_object({}) { |p, hsh|
      hsh[p.staff_id] = p.full_name
    }
  end

  def self.get_pom_name(nomis_staff_id)
    staff = HmppsApi::Prison::PrisonOffenderManager.staff_detail(nomis_staff_id)
    [staff.first_name, staff.last_name]
  end

  def self.get_user_name(username)
    user = HmppsApi::Prison::User.user_details(username)
    [user.first_name, user.last_name]
  end

  def self.unavailable_pom_count(prison)
    poms = get_poms_for(prison).reject { |pom|
      pom.status == 'active'
    }
    poms.count
  end

  def self.get_signed_in_pom_details(current_user, prison)
    user = HmppsApi::Prison::User.user_details(current_user)

    poms_list = get_poms_for(prison)
    poms_list.find { |p| p.staff_id.to_i == user.staff_id.to_i }
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
