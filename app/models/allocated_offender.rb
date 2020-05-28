# frozen_string_literal: true

# This class is a 'presenter' designed to prevent clients having to know whether
# a field lives in the allocation or sentence details when both are returned
# e.g. PomCaseload.new().allocations
#
class AllocatedOffender
  delegate :last_name, :full_name, :earliest_release_date,
           :sentence_start_date, :tier, to: :@offender
  delegate :updated_at, :nomis_offender_id, :primary_pom_allocated_at, :prison,
           to: :@allocation

  attr_reader :offender

  def initialize(staff_id, allocation, offender)
    @staff_id = staff_id
    @allocation = allocation
    @offender = offender
  end

  def latest_movement_date
    @offender.latest_movement&.create_date_time&.to_date
  end

  def pom_responsibility
    @pom_responsibility ||= overridden_responsibility || calculated_responsibility
  end

  # check for changes in the last week where the target value
  # (item[1] in the array) is our staff_id
  def new_case?
    @allocation.versions.where('created_at >= ?', 7.days.ago).map { |c|
      YAML.load(c.object_changes)
    }.select { |c|
      c.key?('primary_pom_nomis_id') && c['primary_pom_nomis_id'][1] == @staff_id ||
      c.key?('secondary_pom_nomis_id') && c['secondary_pom_nomis_id'][1] == @staff_id
    }.any?
  end

private

  def overridden_responsibility
    override = Responsibility.find_by(nomis_offender_id: @offender.offender_no)
    return nil if override.nil?

    if override.value == Responsibility::PRISON
      ResponsibilityService::RESPONSIBLE.to_s
    else
      ResponsibilityService::SUPPORTING.to_s
    end
  end

  def calculated_responsibility
    if @allocation.primary_pom_nomis_id == @staff_id
      ResponsibilityService.calculate_pom_responsibility(offender).to_s
    else
      ResponsibilityService::COWORKING
    end
  end
end
