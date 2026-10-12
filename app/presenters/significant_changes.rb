# frozen_string_literal: true

# Wraps an allocated offender with the outstanding significant changes to their
# case, derived from PaperTrail versions. A change is outstanding if it happened
# after the primary POM was allocated or last reviewed, and within the last
# `LOOKBACK_PERIOD`.
#
# Each type of change is worked out by its own detector in `DETECTORS`. To track
# a new type of change, add a `Detector` subclass and list it there.
#
class SignificantChanges
  DETECTORS = [TierDetector, RoshDetector, HandoverDetector].freeze

  # Only changes within this many days (rolling, up to today) are considered
  LOOKBACK_PERIOD = 30.days

  Change = Data.define(:type, :label, :from_value, :to_value, :changed_at)

  attr_reader :offender, :allocation

  delegate :offender_no, :full_name, to: :offender
  delegate :any?, to: :changes

  # Builds a wrapper for each allocated offender, loading all their versions in
  # a single query. `poms` is a callable returning the prison's POMs, and it's
  # called when a significant change needs comparing with the allocated POM
  #
  def self.for(offenders, allocations, poms:)
    allocations_by_offender = allocations.index_by(&:nomis_offender_id)
    allocated_offenders = offenders.select { allocations_by_offender[it.offender_no]&.primary_pom_allocated_at.present? }
    return [] if allocated_offenders.empty?

    versions_by_offender = load_versions(allocations_by_offender.values_at(*allocated_offenders.map(&:offender_no)))
      .group_by(&:nomis_offender_id)

    allocated_offenders.map do |offender|
      new(offender,
          allocations_by_offender.fetch(offender.offender_no),
          versions_by_offender.fetch(offender.offender_no, []),
          poms:)
    end
  end

  # Loads the versions the detectors might need, for all the allocations at once.
  # This uses the earliest start date across all allocations, so each wrapper
  # then drops any versions from before its own start date
  #
  def self.load_versions(allocations)
    PaperTrail::Version
      .select(:id, :item_type, :item_id, :event, :nomis_offender_id, :created_at, :object_changes)
      .where(item_type: DETECTORS.map(&:item_type).uniq, event: 'update',
             nomis_offender_id: allocations.map(&:nomis_offender_id),
             created_at: allocations.map { start_date_for(it) }.min..)
      .order(:created_at, :id)
  end

  def self.start_date_for(allocation)
    [allocation.primary_pom_allocated_at, allocation.primary_pom_reviewed_at, LOOKBACK_PERIOD.ago.beginning_of_day].compact.max
  end

  def initialize(offender, allocation, versions, poms:)
    @offender = offender
    @allocation = allocation
    @poms = poms

    start_date = self.class.start_date_for(allocation)
    @versions = versions.select { it.created_at >= start_date }
  end

  def changes
    @changes ||= DETECTORS.filter_map { it.new(self, @versions).change }
  end

  def labels = changes.map(&:label)

  def working_days_since_earliest_change
    earliest_change_at = changes.map(&:changed_at).min
    return if earliest_change_at.nil?

    WorkingDayCalculator.working_days_between(earliest_change_at.to_date, Time.zone.today)
  end

  # The position (prison or probation POM) of the allocated primary POM
  def allocated_pom_position
    @poms.call.find { it.staff_id == allocation.primary_pom_nomis_id }&.position
  end

  def recommendation_differs_from_allocation?
    pom_types = [RecommendationService::PRISON_POM, RecommendationService::PROBATION_POM]
    recommended = offender.recommended_pom_type
    allocated = allocated_pom_position

    recommended.in?(pom_types) && allocated.in?(pom_types) && recommended != allocated
  end
end
