# frozen_string_literal: true

class PersistOmicEligibilityService
  API_ARGS = { fetch_complexities: false, fetch_categories: false, fetch_movements: false }.freeze

  def call
    initial_rows = OmicEligibility.count
    log("event=persist_omic_eligibility,rows_start=#{initial_rows}")

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

    final_rows = OmicEligibility.count
    log("event=persist_omic_eligibility,rows_start=#{initial_rows},rows_end=#{final_rows},delta=#{final_rows - initial_rows}")
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
      }
    end

    # Rails still manages `updated_at` here: it refreshes it when any `update_only`
    # column changes, and preserves it when the values are unchanged
    OmicEligibility.upsert_all(
      records, unique_by: :nomis_offender_id, update_only: %i[eligible prison]
    )
  end

  def cleanup_missing_offenders(seen_offender_ids_by_prison)
    log_orphaned_prison_rows(seen_offender_ids_by_prison.keys)

    deleted = 0

    seen_offender_ids_by_prison.each do |prison, seen_offender_ids|
      deleted += OmicEligibility.where(prison:).where.not(nomis_offender_id: seen_offender_ids).delete_all
    end

    deleted
  end

  def log_orphaned_prison_rows(valid_prison_codes)
    orphaned_prisons = (OmicEligibility.distinct.pluck(:prison) - valid_prison_codes)
    return if orphaned_prisons.empty?

    log(
      "event=persist_omic_eligibility,status=orphaned_prison_rows_detected,prisons=#{orphaned_prisons.join(',')}"
    )
  end

  def log(msg)
    self.class.logger.info(msg)
  end
end
