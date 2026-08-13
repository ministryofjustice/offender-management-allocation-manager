# frozen_string_literal: true

class PersistOmicEligibilityService
  API_ARGS = { fetch_complexities: false, fetch_categories: false, fetch_movements: false }.freeze

  # This is set to a conservative approach, meaning it will take 2 runs (~48h)
  # for an offender no longer returned to be deleted from the `OmicEligibility`
  # table. Can be set at 1 to revert to previous "delete immediately" approach
  DEFAULT_MISSING_RUNS_THRESHOLD = 2

  def call
    prison_codes = PrisonService.prison_codes
    seen_offender_ids_by_prison = {}
    failed_prisons = []

    prison_codes.each do |code|
      log("event=persist_omic_eligibility,prison=#{code},status=processing")
      seen_offender_ids_by_prison[code] = process_prison(code)
    rescue StandardError => e
      log("event=persist_omic_eligibility,prison=#{code},status=failed,error=#{e.class},message=#{e.message}")
      failed_prisons << code
    end

    if failed_prisons.any?
      log(
        'event=persist_omic_eligibility,status=skipping_cleanup,' \
          "failed_prisons=#{failed_prisons.join(',')},failed_count=#{failed_prisons.size}"
      )
    else
      deleted = cleanup_missing_offenders(seen_offender_ids_by_prison)
      log("event=persist_omic_eligibility,status=cleanup,deleted=#{deleted}")
    end

    log(
      'event=persist_omic_eligibility,status=complete,' \
        "processed=#{seen_offender_ids_by_prison.values.sum(&:size)}," \
        "prisons_ok=#{prison_codes.size - failed_prisons.size},prisons_total=#{prison_codes.size}"
    )
  end

  def self.logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
  end

private

  def process_prison(prison_code)
    offenders = HmppsApi::PrisonApi::OffenderApi.get_offenders_in_prison(prison_code, **API_ARGS)
    return [] if offenders.empty?

    upsert_for_prison(offenders, prison_code)

    offenders.map(&:offender_no)
  end

  def upsert_for_prison(offender_records, prison_code)
    records = offender_records.map do |offender|
      {
        nomis_offender_id: offender.offender_no,
        eligible: offender.inside_omic_policy?,
        prison: prison_code,
        missing_runs_count: 0,
      }
    end

    # Rails still manages `updated_at` here: it refreshes it when any `update_only`
    # column changes, and preserves it when the values are unchanged
    OmicEligibility.upsert_all(
      records, unique_by: :nomis_offender_id, update_only: %i[eligible prison missing_runs_count]
    )
  end

  # First pass marks offenders as missing, second pass deletes them
  def cleanup_missing_offenders(seen_offender_ids_by_prison)
    log_orphaned_prison_rows(seen_offender_ids_by_prison.keys)

    seen_offender_ids_by_prison.each do |prison_code, seen_offender_ids|
      OmicEligibility
        .where(prison: prison_code)
        .where.not(nomis_offender_id: seen_offender_ids)
        .update_all('missing_runs_count = missing_runs_count + 1')
    end

    log_pending_cleanup_counts

    OmicEligibility.where('missing_runs_count >= ?', threshold).delete_all
  end

  def log_orphaned_prison_rows(valid_prison_codes)
    orphaned_prisons = (OmicEligibility.distinct.pluck(:prison) - valid_prison_codes)
    return if orphaned_prisons.empty?

    log(
      "event=persist_omic_eligibility,status=orphaned_prison_rows_detected,prisons=#{orphaned_prisons.join(',')}"
    )
  end

  def log_pending_cleanup_counts
    due_now = OmicEligibility.where('missing_runs_count >= ?', threshold).count
    due_next_run = threshold > 1 ? OmicEligibility.where(missing_runs_count: threshold - 1).count : 0

    log(
      'event=persist_omic_eligibility,status=cleanup_pending,' \
        "threshold=#{threshold},due_now=#{due_now},due_next_run=#{due_next_run}"
    )
  end

  def threshold
    DEFAULT_MISSING_RUNS_THRESHOLD
  end

  def log(msg)
    self.class.logger.info(msg)
  end
end
