# This class is a 'presenter' designed to prevent clients having to know whether
# a field lives in the allocation or sentence details when both are returned
# e.g. PrisonerOffenderManagerService#get_allocated_offenders
#
class AllocationWithSentence
  delegate :last_name, :full_name, :earliest_release_date,
           :sentence_start_date, to: :@sentence
  delegate :updated_at, :nomis_offender_id, :primary_pom_allocated_at,
           :allocated_at_tier, to: :@allocation
  delegate :handover_start_date, :responsibility_handover_date,
            to: :offender

  attr_reader :responsibility

  def initialize(staff_id, allocation, sentence, responsibility)
    @staff_id = staff_id
    @allocation = allocation
    @sentence = sentence
    @responsibility = responsibility
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
  def offender
    @offender ||= OffenderService.get_offender(@allocation.nomis_offender_id)
  end
end
