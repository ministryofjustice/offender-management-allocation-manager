class DeactivateReleasedCnlsJob < ApplicationJob
  queue_as :default

  attr_reader :prison, :inactivated_count, :errors_count

  def perform(prison)
    @prison = prison
    @inactivated_count = 0
    @errors_count = 0

    offender_nos = AllocationHistory.where(
      prison: prison.code,
      event_trigger: AllocationHistory::OFFENDER_RELEASED,
    ).pluck(:nomis_offender_id)

    offender_count = offender_nos.size
    log("Processing #{offender_count} released offenders...")

    offender_nos.each do |nomis_offender_id|
      process_offender(nomis_offender_id)
    end

    log("Done. Inactivated: #{inactivated_count}/#{offender_count}. Errors: #{errors_count}.")
  end

private

  def process_offender(nomis_offender_id)
    with_retries { HmppsApi::ComplexityApi.inactivate(nomis_offender_id) }
    @inactivated_count += 1
  rescue StandardError => e
    log("Offender ID #{nomis_offender_id} produced an error: #{e.message}")
    @errors_count += 1
  end

  def with_retries(pause_secs: 5, retry_limit: 3)
    retry_limit.times do |i|
      return yield
    rescue Faraday::ServerError
      if (i + 1) == retry_limit
        log("API error: #{retry_limit} re-try limit reached")
        raise
      end

      log("API error. Pausing #{pause_secs}s before re-trying")
      sleep pause_secs
    end
  end

  def log(msg)
    logger.info("[#{self.class.name}] [#{prison.code}] #{msg}")
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
