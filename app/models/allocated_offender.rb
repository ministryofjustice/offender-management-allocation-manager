# frozen_string_literal: true

# This class is a 'presenter' designed to prevent clients having to know whether
# a field lives in the allocation or sentence details when both are returned
# e.g. PomCaseload.new().allocations
#
class AllocatedOffender
  delegate :last_name, :full_name, :earliest_release_date, :approaching_handover?,
           :indeterminate_sentence?, :prison_id, :parole_review_date, :delius_matched?,
           :handover_start_date, :responsibility_handover_date, :allocated_com_name, :case_allocation,
           :complexity_level, :offender_no, :sentence_start_date, :tier, :cell_location, :latest_temp_movement_date, to: :@offender
  delegate :updated_at, :nomis_offender_id, :primary_pom_allocated_at, :prison,
           to: :@allocation

  COMPLEXITIES = { 'high' => 3, 'medium' => 2, 'low' => 1 }.freeze

  def initialize(staff_id, allocation, offender)
    @staff_id = staff_id
    @allocation = allocation
    @offender = offender
  end

  # this is required for sorting only
  def complexity_level_number
    COMPLEXITIES.fetch(complexity_level)
  end

  def high_complexity?
    complexity_level == 'high'
  end

  def pom_responsibility
    if @allocation.primary_pom_nomis_id == @staff_id
      @offender.pom_responsible? ? 'Responsible' : 'Supporting'
    else
      'Co-Working'
    end
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
end
