# frozen_string_literal: true

# This object represents a staff member who may or my not be a POM. It is up to the caller to check
# and do something interesting if they are not a POM at a specific prison.
class StaffMember
  attr_reader :staff_id

  def initialize(nomis_staff_id, pom_detail = default_pom_detail(nomis_staff_id))
    @staff_id = nomis_staff_id.to_i
    @pom_detail = pom_detail
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

  def first_name
    staff_detail.first_name&.titleize
  end

  def last_name
    staff_detail.last_name&.titleize
  end

  def email_address
    HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@staff_id).first
  end

  def pom_at?(prison_id)
    poms_list = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison_id)

    poms_list.detect { |pom| pom.staff_id == @staff_id }.present?
  end

  def position(prison_id)
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison_id)
    this_pom = poms.detect { |pom| pom.staff_id == @staff_id }
    if this_pom.nil?
      'STAFF'
    elsif this_pom.prison_officer?
      RecommendationService::PRISON_POM
    else
      RecommendationService::PROBATION_POM
    end
  end

  def working_pattern
    @pom_detail.working_pattern
  end

  def status
    @pom_detail.status
  end

private

  def default_pom_detail(staff_id)
    @pom_detail = PomDetail.find_or_create_by!(nomis_staff_id: staff_id) { |pom|
      pom.working_pattern = 0.0
      pom.status = 'active'
    }
  end

  def staff_detail
    @staff_detail ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(@staff_id)
  end
end
