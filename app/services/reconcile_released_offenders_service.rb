# frozen_string_literal: true

# Manual backlog cleanup for offenders who still have local stale data
# (CaseInformation, CalculatedHandoverDate, etc.) or active allocations,
# but are no longer present in a managed prison.
#
# Relies on the `OmicEligibility` table, which is populated daily by the
# `persist_omic_eligibility` cron job. Run this task manually only after that
# snapshot is fresh.
#
class ReconcileReleasedOffendersService
  DEFAULT_BATCH_SIZE = 500

  Result = Struct.new(
    :dry_run,
    :candidate_count,
    :unresolved_ids,
    :released_ids,
    :skipped_counts_by_prison,
    :api_found_in_search_count,
    :api_resolved_to_target_prisons_count,
    :api_resolved_to_other_prisons_count,
    :api_not_found_in_search_count,
    keyword_init: true
  ) do
    delegate :to_a, to: :released_ids

    def released_count = released_ids.size
    def skipped_count  = skipped_counts_by_prison.values.sum
    def unresolved_count = unresolved_ids.size
    def api_resolution_candidates_count = api_found_in_search_count + api_not_found_in_search_count
  end

  attr_reader :dry_run, :batch_size

  def initialize(
    dry_run: true,
    prison_codes: nil,
    batch_size: DEFAULT_BATCH_SIZE
  )
    @dry_run = dry_run
    @prison_codes = Array(prison_codes).presence || PrisonService.prison_codes
    @batch_size = batch_size
  end

  def call
    orphaned_ids_by_prison, unresolved_ids, attribution_stats = find_orphaned_offender_ids_by_prison
    candidate_count = orphaned_ids_by_prison.values.sum(&:size)

    log(
      "event=reconcile_start,candidate_count=#{candidate_count},unresolved_count=#{unresolved_ids.size}," \
        "prisons=#{@prison_codes.size},batch_size=#{batch_size},dry_run=#{dry_run}"
    )

    log(
      "event=reconcile_attribution_summary,api_candidates=#{attribution_stats.fetch(:api_candidates)}," \
        "api_found_in_search=#{attribution_stats.fetch(:api_found_in_search)}," \
        "api_resolved_to_target_prisons=#{attribution_stats.fetch(:api_resolved_to_target_prisons)}," \
        "api_resolved_to_other_prisons=#{attribution_stats.fetch(:api_resolved_to_other_prisons)}," \
        "api_not_found_in_search=#{attribution_stats.fetch(:api_not_found_in_search)}," \
        "still_unresolved=#{attribution_stats.fetch(:still_unresolved)}"
    )

    if unresolved_ids.any?
      log(
        "event=reconcile_unresolved_orphans,count=#{unresolved_ids.size},sample_nomis_ids=#{unresolved_ids.first(10).join(',')}"
      )
    end

    released_ids = Set.new
    skipped_counts_by_prison = Hash.new(0)

    @prison_codes.each do |prison_code|
      prison_result = process_prison(prison_code, orphaned_ids_by_prison[prison_code])
      released_ids.merge(prison_result.fetch(:released_ids))
      skipped_counts_by_prison[prison_code] += prison_result.fetch(:skipped_count)
    rescue StandardError => e
      skipped_counts_by_prison[prison_code] += orphaned_ids_by_prison[prison_code].size
      log("event=reconcile_prison_error,prison=#{prison_code},error=#{e.class},message=#{e.message}")
    end

    build_result(
      candidate_count:,
      unresolved_ids:,
      released_ids:,
      skipped_counts_by_prison:,
      api_found_in_search_count: attribution_stats.fetch(:api_found_in_search),
      api_resolved_to_target_prisons_count: attribution_stats.fetch(:api_resolved_to_target_prisons),
      api_resolved_to_other_prisons_count: attribution_stats.fetch(:api_resolved_to_other_prisons),
      api_not_found_in_search_count: attribution_stats.fetch(:api_not_found_in_search)
    ).tap do |result|
      log(
        "event=reconcile_complete,candidate_count=#{result.candidate_count},confirmed_released_count=#{result.released_count}," \
          "not_confirmed_count=#{result.skipped_count},unresolved_count=#{result.unresolved_count}," \
          "api_resolved_to_other_prisons=#{result.api_resolved_to_other_prisons_count}," \
          "api_not_found_in_search=#{result.api_not_found_in_search_count},dry_run=#{dry_run}"
      )
    end
  end

  def self.logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
  end

private

  def empty_result
    build_result(
      candidate_count: 0,
      unresolved_ids: Set.new,
      released_ids: Set.new,
      skipped_counts_by_prison: {},
      api_found_in_search_count: 0,
      api_resolved_to_target_prisons_count: 0,
      api_resolved_to_other_prisons_count: 0,
      api_not_found_in_search_count: 0
    )
  end

  def build_result(
    candidate_count:,
    unresolved_ids:,
    released_ids:,
    skipped_counts_by_prison:,
    api_found_in_search_count:,
    api_resolved_to_target_prisons_count:,
    api_resolved_to_other_prisons_count:,
    api_not_found_in_search_count:
  )
    Result.new(
      dry_run:,
      candidate_count:,
      unresolved_ids:,
      released_ids:,
      skipped_counts_by_prison:,
      api_found_in_search_count:,
      api_resolved_to_target_prisons_count:,
      api_resolved_to_other_prisons_count:,
      api_not_found_in_search_count:
    )
  end

  # Returns:
  # - a Hash keyed by prison code with orphaned offender IDs as Sets
  # - a Set of orphaned offender IDs we could not safely attribute to a prison
  #
  # Active allocations already carry local prison context (`AllocationHistory.prison`)
  #
  # For other stint rows where prison context is ambiguous, we use batched
  # prisoner-search lookup and derive prison from prisonId (or lastPrisonId if OUT)
  #
  def find_orphaned_offender_ids_by_prison
    orphaned_ids_by_prison = Hash.new { |hash, prison_code| hash[prison_code] = Set.new }
    unresolved_ids = Set.new

    merge_rows_by_prison!(
      orphaned_ids_by_prison,
      unresolved_ids,
      orphaned_allocation_rows
    )

    orphaned_stint_ids.each { unresolved_ids << it }
    orphaned_ids_by_prison.each_value { unresolved_ids.subtract(it) }

    attribution_stats = resolve_prisons_from_prisoner_search!(orphaned_ids_by_prison, unresolved_ids)

    [orphaned_ids_by_prison, unresolved_ids, attribution_stats]
  end

  # For one prison: bulk-fetch confirmed releases from prisoner-search,
  # cross with the global orphaned set, then release the intersection
  def process_prison(prison_code, orphaned_ids)
    return { released_ids: Set.new, skipped_count: 0 } if orphaned_ids.blank?

    confirmed = Set.new
    legal_status_candidates = Set.new

    orphaned_ids.each_slice(batch_size).with_index(1) do |batch_ids, index|
      batch_set = batch_ids.to_set
      summaries = offender_summaries_for(batch_set)
      found_ids = summaries.keys.to_set
      not_found_ids = batch_set - found_ids
      legal_status_batch = found_ids.select { |nomis_offender_id|
        legal_status_requires_status_job?(summaries.fetch(nomis_offender_id))
      }.to_set
      releasable_from_search = found_ids.select { |nomis_offender_id|
        prune_candidate_for_prison?(summaries.fetch(nomis_offender_id))
      }.to_set

      confirmed_batch = releasable_from_search | not_found_ids
      confirmed.merge(confirmed_batch)
      legal_status_candidates.merge(legal_status_batch)

      log(
        "event=reconcile_prison_batch,prison=#{prison_code},batch=#{index},candidates=#{batch_set.size}," \
          "confirmed_released=#{confirmed_batch.size},found_in_search=#{found_ids.size}," \
          "not_found_in_search=#{not_found_ids.size},legal_status_candidates=#{legal_status_batch.size},dry_run=#{dry_run}"
      )
    end

    to_release = orphaned_ids & confirmed
    skipped_count = orphaned_ids.size - to_release.size

    log("event=reconcile_prison,prison=#{prison_code},confirmed_released=#{confirmed.size}," \
          "to_release=#{to_release.size},not_confirmed=#{skipped_count},dry_run=#{dry_run}")

    status_only_candidates = legal_status_candidates - to_release

    unless dry_run
      to_release.each { release_offender(it, prison_code:) }
      status_only_candidates.each { process_legal_status_change(it) }
    end

    log(
      "event=reconcile_prison_status_actions,prison=#{prison_code}," \
        "status_only_candidates=#{status_only_candidates.size},dry_run=#{dry_run}"
    )

    { released_ids: to_release, skipped_count: }
  end

  def orphaned_allocation_rows
    AllocationHistory
      .active
      .where(prison: @prison_codes)
      .where.not(nomis_offender_id: OmicEligibility.select(:nomis_offender_id))
      .distinct
      .pluck(:prison, :nomis_offender_id)
  end

  def orphaned_stint_ids
    OffenderReleasedService::STINT_DATA_MODELS.each_with_object(Set.new) do |model, orphaned_ids|
      orphaned_ids.merge(
        model
          .where.not(nomis_offender_id: OmicEligibility.select(:nomis_offender_id))
          .distinct
          .pluck(:nomis_offender_id)
      )
    end
  end

  def resolve_prisons_from_prisoner_search!(orphaned_ids_by_prison, unresolved_ids)
    if unresolved_ids.empty?
      return {
        api_candidates: 0,
        api_found_in_search: 0,
        api_resolved_to_target_prisons: 0,
        api_resolved_to_other_prisons: 0,
        api_not_found_in_search: 0,
        still_unresolved: 0
      }
    end

    initial_unresolved_count = unresolved_ids.size
    resolved_ids = Set.new
    found_in_search_count = 0
    resolved_to_target_prisons_count = 0
    resolved_to_other_prisons_count = 0
    not_found_in_search_total = 0

    unresolved_ids.each_slice(batch_size).with_index(1) do |batch_ids, index|
      batch_set = batch_ids.to_set
      summaries = offender_summaries_for(batch_set)
      resolved_in_batch = Set.new
      outside_target_prisons_in_batch = Set.new

      summaries.each do |nomis_offender_id, attributes|
        prison_code = prison_code_from_summary(attributes)
        next if prison_code.blank?

        unless @prison_codes.include?(prison_code)
          outside_target_prisons_in_batch << nomis_offender_id
          next
        end

        orphaned_ids_by_prison[prison_code] << nomis_offender_id
        resolved_ids << nomis_offender_id
        resolved_in_batch << nomis_offender_id
      end

      found_in_search = summaries.keys.to_set
      not_found_in_search_count = batch_set.size - found_in_search.size
      found_in_search_count += found_in_search.size
      resolved_to_target_prisons_count += resolved_in_batch.size
      resolved_to_other_prisons_count += outside_target_prisons_in_batch.size
      not_found_in_search_total += not_found_in_search_count

      log(
        "event=reconcile_prison_resolution_batch,batch=#{index},unresolved_candidates=#{batch_set.size}," \
          "found_in_search=#{found_in_search.size},resolved_to_target_prisons=#{resolved_in_batch.size}," \
          "outside_target_prisons=#{outside_target_prisons_in_batch.size},not_found_in_search=#{not_found_in_search_count}," \
          "still_unresolved=#{batch_set.size - resolved_in_batch.size}"
      )
    rescue StandardError => e
      not_found_in_search_total += batch_set.size
      log(
        "event=reconcile_prison_resolution_batch_error,batch=#{index},unresolved_candidates=#{batch_set.size}," \
          "error=#{e.class},message=#{e.message}"
      )
    end

    unresolved_ids.subtract(resolved_ids)

    {
      api_candidates: initial_unresolved_count,
      api_found_in_search: found_in_search_count,
      api_resolved_to_target_prisons: resolved_to_target_prisons_count,
      api_resolved_to_other_prisons: resolved_to_other_prisons_count,
      api_not_found_in_search: not_found_in_search_total,
      still_unresolved: unresolved_ids.size
    }
  end

  def prune_candidate_for_prison?(summary_attributes)
    prison_id = summary_attributes['prisonId']
    restricted_patient = summary_attributes['restrictedPatient']

    return false if prison_id == HmppsApi::MovementDirection::OUT && restricted_patient
    return false if temp_out_of_prison_from_summary?(summary_attributes)
    return true if prison_id == HmppsApi::MovementDirection::OUT

    false
  end

  def temp_out_of_prison_from_summary?(summary_attributes)
    summary_attributes['inOutStatus'] == HmppsApi::MovementDirection::OUT &&
      summary_attributes['lastMovementTypeCode'] == HmppsApi::MovementType::TEMPORARY
  end

  def legal_status_requires_status_job?(summary_attributes)
    prison_id = summary_attributes['prisonId']
    legal_status = summary_attributes['legalStatus']

    return false if prison_id == HmppsApi::MovementDirection::OUT

    allowed_legal_statuses_for_status_job.exclude?(legal_status)
  end

  def allowed_legal_statuses_for_status_job
    HmppsApi::PrisonApi::OffenderApi::ALLOWED_LEGAL_STATUSES
  end

  def prison_code_from_summary(summary_attributes)
    prison_id = summary_attributes['prisonId']
    return summary_attributes['lastPrisonId'] if prison_id == HmppsApi::MovementDirection::OUT

    prison_id
  end

  # Cache Prisoner Search summaries during one service run so we do not query the
  # same offender IDs twice across attribution and per-prison confirmation phases.
  def offender_summaries_for(offender_ids)
    ids = offender_ids.to_set
    missing_ids = ids - summary_ids_queried

    if missing_ids.any?
      found_summaries = HmppsApi::PrisonApi::OffenderApi.offender_summaries_for(missing_ids, cache: false) || {}
      summary_cache.merge!(found_summaries)
      summary_ids_queried.merge(missing_ids)
    end

    ids.each_with_object({}) do |nomis_offender_id, result|
      summary = summary_cache[nomis_offender_id]
      result[nomis_offender_id] = summary if summary
    end
  end

  def summary_cache
    @summary_cache ||= {}
  end

  def summary_ids_queried
    @summary_ids_queried ||= Set.new
  end

  def merge_rows_by_prison!(orphaned_ids_by_prison, unresolved_ids, rows)
    rows.each do |prison_code, nomis_offender_id|
      if prison_code.present?
        orphaned_ids_by_prison[prison_code] << nomis_offender_id
      else
        unresolved_ids << nomis_offender_id
      end
    end
  end

  def release_offender(nomis_offender_id, prison_code:)
    log("event=reconcile_release,nomis_offender_id=#{nomis_offender_id},prison=#{prison_code}")
    OffenderReleasedService.release_offender(nomis_offender_id, prison_code:, send_email: false)
  rescue StandardError => e
    log("event=reconcile_release_error,nomis_offender_id=#{nomis_offender_id},error=#{e.class},message=#{e.message}")
  end

  def process_legal_status_change(nomis_offender_id)
    log("event=reconcile_legal_status_change,nomis_offender_id=#{nomis_offender_id}")
    ProcessPrisonerStatusJob.perform_now(nomis_offender_id, trigger_method: :reconcile)
  rescue StandardError => e
    log(
      "event=reconcile_legal_status_change_error,nomis_offender_id=#{nomis_offender_id}," \
      "error=#{e.class},message=#{e.message}"
    )
  end

  def log(msg)
    self.class.logger.info("[ReconcileReleasedOffendersService] #{msg}")
  end
end
