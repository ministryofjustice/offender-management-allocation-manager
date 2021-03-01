# frozen_string_literal: true

class PrisonOffenderManagerService
  # Note - get_poms_for and get_pom_at return different data...
  def self.get_poms_for(prison)
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison).
      select { |pom| pom.prison_officer? || pom.probation_officer? }.uniq(&:staff_id)

    pom_details = PomDetail.where(nomis_staff_id: poms.map(&:staff_id))

    poms.each { |pom|
      detail = get_pom_detail(pom_details, pom.staff_id.to_i)
      pom.status = detail.status
      pom.working_pattern = detail.working_pattern
    }
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

    StaffMember.new(Prison.new(prison_id), pom.staff_id)
  end

  def self.get_pom_emails(nomis_staff_id)
    HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(nomis_staff_id)
  end

  def self.get_pom_names(prison)
    poms_list = get_poms_for(prison)
    poms_list.each_with_object({}) { |p, hsh|
      hsh[p.staff_id] = p.full_name
    }
  end

  def self.get_pom_name(nomis_staff_id)
    staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(nomis_staff_id)
    [staff.first_name, staff.last_name]
  end

  def self.get_user_name(username)
    user = HmppsApi::PrisonApi::UserApi.user_details(username)
    [user.first_name, user.last_name]
  end

  def self.unavailable_pom_count(prison)
    poms = get_poms_for(prison).reject { |pom|
      pom.status == 'active'
    }
    poms.count
  end

  def self.get_signed_in_pom_details(current_user, prison)
    user = HmppsApi::PrisonApi::UserApi.user_details(current_user)

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
