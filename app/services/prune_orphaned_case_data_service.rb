# frozen_string_literal: true

# Prunes `CaseInformation` (and associated stint data) for offenders who are
# almost certainly no longer in scope for the service, based on:
#
#   1. Never had any AllocationHistory row, and not updated for X months or more.
#      Mostly cases imported via Delius/tier events but never reached allocation.
#
#   2. Have an AllocationHistory row whose last event_trigger is `offender_released`.
#      The service already recorded the release so local stint data can be cleared.
#
class PruneOrphanedCaseDataService
  DEFAULT_NEVER_ALLOCATED_MIN_AGE_MONTHS = 3
  DEFAULT_BATCH_SIZE = 500

  Result = Struct.new(
    :dry_run,
    :never_allocated_ids,
    :released_allocation_ids,
    keyword_init: true
  ) do
    def never_allocated_count = never_allocated_ids.size
    def released_allocation_count = released_allocation_ids.size
    def total_count = (never_allocated_ids | released_allocation_ids).size
  end

  attr_reader :dry_run, :never_allocated_min_age, :batch_size

  def initialize(
    dry_run: true,
    never_allocated_min_age: DEFAULT_NEVER_ALLOCATED_MIN_AGE_MONTHS.months,
    batch_size: DEFAULT_BATCH_SIZE
  )
    @dry_run = dry_run
    @never_allocated_min_age = never_allocated_min_age
    @batch_size = batch_size
  end

  def call
    never_allocated_ids = find_never_allocated_ids
    released_allocation_ids = find_released_via_allocation_ids
    all_ids = (never_allocated_ids | released_allocation_ids)

    log(
      "event=prune_start,never_allocated=#{never_allocated_ids.size}," \
        "released_via_allocation=#{released_allocation_ids.size}," \
        "total=#{all_ids.size},dry_run=#{dry_run}"
    )

    prune_stint_data(all_ids) unless dry_run
    log("event=prune_complete,total_pruned=#{dry_run ? 0 : all_ids.size},dry_run=#{dry_run}")

    Result.new(dry_run:, never_allocated_ids:, released_allocation_ids:)
  end

  def self.logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
  end

private

  # Offenders with CaseInformation, no AllocationHistory ever, not in
  # OmicEligibility, and not updated recently
  #
  def find_never_allocated_ids
    cutoff = ApplicationRecord.connection.quote(never_allocated_min_age.ago)

    ApplicationRecord.connection.select_values(<<~SQL.squish)
      SELECT ci.nomis_offender_id
      FROM case_information ci
      WHERE ci.updated_at < #{cutoff}
        AND NOT EXISTS (
          SELECT 1 FROM allocation_history ah
          WHERE ah.nomis_offender_id = ci.nomis_offender_id
        )
        AND NOT EXISTS (
          SELECT 1 FROM omic_eligibilities oe
          WHERE oe.nomis_offender_id = ci.nomis_offender_id
        )
    SQL
  end

  # Offenders with CaseInformation, an AllocationHistory whose last recorded
  # event_trigger is `offender_released`, and not in OmicEligibility
  #
  def find_released_via_allocation_ids
    ApplicationRecord.connection.select_values(<<~SQL.squish)
      SELECT ci.nomis_offender_id
      FROM case_information ci
      INNER JOIN allocation_history ah
        ON ah.nomis_offender_id = ci.nomis_offender_id
        AND ah.event_trigger = #{AllocationHistory::OFFENDER_RELEASED}
      WHERE NOT EXISTS (
        SELECT 1 FROM omic_eligibilities oe
        WHERE oe.nomis_offender_id = ci.nomis_offender_id
      )
    SQL
  end

  def prune_stint_data(nomis_offender_ids)
    nomis_offender_ids.each_slice(batch_size) do |batch_ids|
      OffenderReleasedService::STINT_DATA_MODELS.each do |model|
        count = model.where(nomis_offender_id: batch_ids).delete_all
        log("event=prune_batch,model=#{model},deleted=#{count}") if count.positive?
      end
    end
  end

  def log(msg)
    self.class.logger.info("[PruneOrphanedCaseDataService] #{msg}")
  end
end
